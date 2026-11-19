import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'khalashi_token';
  static const _langKey = 'khalashi_lang';
  static const _phoneKey = 'khalashi_phone';
  static const _recentCitiesKey = 'khalashi_recent_cities';

  /// Cap for persisted From/To city history (newest first).
  static const recentCitiesLimit = 10;

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

  /// Newest-first list of recently used city names (display casing preserved).
  Future<List<String>> getRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_recentCitiesKey) ?? const []);
  }

  /// Push [city] to the front of recent cities. Case-insensitive dedupe; cap at [recentCitiesLimit].
  Future<void> addRecentCity(String city) async {
    final trimmed = city.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = List<String>.from(prefs.getStringList(_recentCitiesKey) ?? const []);
    final lower = trimmed.toLowerCase();
    existing.removeWhere((c) => c.toLowerCase() == lower);
    existing.insert(0, trimmed);
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
