import 'package:shared_preferences/shared_preferences.dart';

import '../data/suggested_cities.dart';

class SessionStore {
  static const _tokenKey = 'khalashi_token';
  static const _langKey = 'khalashi_lang';
  static const _phoneKey = 'khalashi_phone';
  static const _recentCitiesKey = 'khalashi_recent_cities';

  /// Cap for persisted From/To city history (newest first).
  static const recentCitiesLimit = 10;

  /// Places filled via "Use current location" that are not on the curated list.
  /// In-memory for this app session so Search/Publish still accept them.
  final Set<String> _gpsAcceptedLower = {};

  Future<void> saveSession({required String token, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_phoneKey, phone);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
  }

  Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey);
  }

  /// Remember a GPS-derived place so typed-list validation still accepts it.
  void acceptGpsCity(String city) {
    final key = city.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (key.isEmpty) return;
    _gpsAcceptedLower.add(key);
  }

  bool isGpsAcceptedCity(String city) {
    final key = city.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return key.isNotEmpty && _gpsAcceptedLower.contains(key);
  }

  /// Curated city, or a GPS-accepted reverse-geocode place for this session.
  String? resolveAcceptedCity(String raw) {
    return resolveTripCity(raw, gpsAcceptedLower: _gpsAcceptedLower);
  }

  /// Newest-first: curated cities, plus GPS-accepted places already stored.
  Future<List<String>> getRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentCitiesKey) ?? const <String>[];
    final out = <String>[];
    final seen = <String>{};
    for (final city in raw) {
      final name = resolveAcceptedCity(city);
      if (name == null) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(name);
    }
    return out;
  }

  /// Push a curated or GPS-accepted [city] to the front.
  /// Case-insensitive dedupe; stores canonical/display casing; cap at [recentCitiesLimit].
  Future<void> addRecentCity(String city) async {
    final canonical = resolveAcceptedCity(city);
    if (canonical == null) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = List<String>.from(prefs.getStringList(_recentCitiesKey) ?? const []);
    final lower = canonical.toLowerCase();
    existing.removeWhere((c) => c.toLowerCase() == lower);
    existing.insert(0, canonical);
    if (existing.length > recentCitiesLimit) {
      existing.removeRange(recentCitiesLimit, existing.length);
    }
    await prefs.setStringList(_recentCitiesKey, existing);
  }

  Future<void> addRecentCities(Iterable<String> cities) async {
    for (final city in cities) {
      await addRecentCity(city);
    }
  }
}
