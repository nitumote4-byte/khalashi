import 'dart:math' as math;

/// Curated India cities for From/To (v1 picklist).
/// Display names are canonical English spellings used in search/publish.
class IndiaCity {
  const IndiaCity(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;
}

const List<IndiaCity> kIndiaCities = [
  IndiaCity('Ahmedabad', 23.0225, 72.5714),
  IndiaCity('Amritsar', 31.6340, 74.8723),
  IndiaCity('Arrah', 25.5560, 84.6633),
  IndiaCity('Aurangabad', 19.8762, 75.3433),
  IndiaCity('Begusarai', 25.4182, 86.1272),
  IndiaCity('Bengaluru', 12.9716, 77.5946),
  IndiaCity('Bhagalpur', 25.2425, 86.9842),
  IndiaCity('Bhopal', 23.2599, 77.4126),
  IndiaCity('Bhubaneswar', 20.2961, 85.8245),
  IndiaCity('Bihar Sharif', 25.1973, 85.5239),
  IndiaCity('Chandigarh', 30.7333, 76.7794),
  IndiaCity('Chapra', 25.7810, 84.7477),
  IndiaCity('Chennai', 13.0827, 80.2707),
  IndiaCity('Coimbatore', 11.0168, 76.9558),
  IndiaCity('Darbhanga', 26.1542, 85.8918),
  IndiaCity('Dehradun', 30.3165, 78.0322),
  IndiaCity('Delhi', 28.6139, 77.2090),
  IndiaCity('Gaya', 24.7955, 85.0002),
  IndiaCity('Goa', 15.2993, 74.1240),
  IndiaCity('Guwahati', 26.1445, 91.7362),
  IndiaCity('Gwalior', 26.2183, 78.1828),
  IndiaCity('Hajipur', 25.6858, 85.2144),
  IndiaCity('Hyderabad', 17.3850, 78.4867),
  IndiaCity('Indore', 22.7196, 75.8577),
  IndiaCity('Jaipur', 26.9124, 75.7873),
  IndiaCity('Jodhpur', 26.2389, 73.0243),
  IndiaCity('Kanpur', 26.4499, 80.3319),
  IndiaCity('Katihar', 25.5397, 87.5670),
  IndiaCity('Kochi', 9.9312, 76.2673),
  IndiaCity('Kolkata', 22.5726, 88.3639),
  IndiaCity('Lucknow', 26.8467, 80.9462),
  IndiaCity('Ludhiana', 30.9010, 75.8573),
  IndiaCity('Madurai', 9.9252, 78.1198),
  IndiaCity('Mangaluru', 12.9141, 74.8560),
  IndiaCity('Motihari', 26.6469, 84.9089),
  IndiaCity('Mumbai', 19.0760, 72.8777),
  IndiaCity('Muzaffarpur', 26.1225, 85.3906),
  IndiaCity('Mysuru', 12.2958, 76.6394),
  IndiaCity('Nagpur', 21.1458, 79.0882),
  IndiaCity('Nashik', 19.9975, 73.7898),
  IndiaCity('Noida', 28.5355, 77.3910),
  IndiaCity('Patna', 25.5941, 85.1376),
  IndiaCity('Pune', 18.5204, 73.8567),
  IndiaCity('Purnia', 25.7771, 87.4753),
  IndiaCity('Raipur', 21.2514, 81.6296),
  IndiaCity('Rajkot', 22.3039, 70.8022),
  IndiaCity('Ranchi', 23.3441, 85.3096),
  IndiaCity('Saharsa', 25.8835, 86.6005),
  IndiaCity('Samastipur', 25.8629, 85.7810),
  IndiaCity('Shimla', 31.1048, 77.1734),
  IndiaCity('Siwan', 26.2208, 84.3567),
  IndiaCity('Surat', 21.1702, 72.8311),
  IndiaCity('Thiruvananthapuram', 8.5241, 76.9366),
  IndiaCity('Udaipur', 24.5854, 73.7125),
  IndiaCity('Vadodara', 22.3072, 73.1812),
  IndiaCity('Varanasi', 25.3176, 82.9739),
  IndiaCity('Vijayawada', 16.5062, 80.6480),
  IndiaCity('Visakhapatnam', 17.6868, 83.2185),
];

/// Canonical display names (same order as [kIndiaCities]).
final List<String> kSuggestedCities =
    List<String>.unmodifiable(kIndiaCities.map((c) => c.name));

final Map<String, String> _canonicalByLower = {
  for (final c in kIndiaCities) c.name.toLowerCase(): c.name,
  // Common aliases that reverse-geocode / users may type.
  'bangalore': 'Bengaluru',
  'bengalooru': 'Bengaluru',
  'mysore': 'Mysuru',
  'mangalore': 'Mangaluru',
  'trivandrum': 'Thiruvananthapuram',
  'tvm': 'Thiruvananthapuram',
  'bombay': 'Mumbai',
  'calcutta': 'Kolkata',
  'madras': 'Chennai',
  'new delhi': 'Delhi',
  'delhi ncr': 'Delhi',
  'gurgaon': 'Delhi',
  'gurugram': 'Delhi',
  'panaji': 'Goa',
  'panjim': 'Goa',
  'vasco': 'Goa',
  'margao': 'Goa',
  'ara': 'Arrah',
  'biharsharif': 'Bihar Sharif',
};

String _normalizeKey(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Exact / alias match → canonical curated name; otherwise null.
String? resolveCuratedCity(String raw) {
  final key = _normalizeKey(raw);
  if (key.isEmpty) return null;
  return _canonicalByLower[key];
}

bool isCuratedCity(String raw) => resolveCuratedCity(raw) != null;

/// Curated city with lat/lng for map centering; null if unknown.
IndiaCity? lookupCuratedCity(String raw) {
  final name = resolveCuratedCity(raw);
  if (name == null) return null;
  for (final city in kIndiaCities) {
    if (city.name == name) return city;
  }
  return null;
}

/// Display form for a free-form place (GPS reverse-geocode).
String displayPlaceName(String raw) {
  final curated = resolveCuratedCity(raw);
  if (curated != null) return curated;
  final parts = raw.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
  return parts
      .where((p) => p.isNotEmpty)
      .map((w) {
        if (w.length == 1) return w.toUpperCase();
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      })
      .join(' ');
}

/// Clean a reverse-geocode label into a usable city/locality name.
String? cleanPlaceLabel(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return null;
  if (RegExp(r'^\d+$').hasMatch(s)) return null;
  // Drop pure country labels.
  final lower = s.toLowerCase();
  if (lower == 'india' || lower == 'भारत') return null;
  return displayPlaceName(s);
}

/// Curated list match, or a GPS-accepted place name from [gpsAcceptedLower].
String? resolveTripCity(String raw, {Set<String>? gpsAcceptedLower}) {
  final curated = resolveCuratedCity(raw);
  if (curated != null) return curated;
  final key = _normalizeKey(raw);
  if (key.isEmpty) return null;
  if (gpsAcceptedLower != null && gpsAcceptedLower.contains(key)) {
    return displayPlaceName(raw);
  }
  return null;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      cur[j + 1] = math.min(
        prev[j + 1] + 1,
        math.min(cur[j] + 1, prev[j] + cost),
      );
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = cur[j];
    }
  }
  return prev[b.length];
}

int _fuzzyScore(String queryLower, String cityLower) {
  if (cityLower == queryLower) return 0;
  if (cityLower.startsWith(queryLower)) return 1;
  if (cityLower.contains(queryLower)) return 2 + cityLower.indexOf(queryLower);

  final maxDist = queryLower.length <= 3 ? 1 : (queryLower.length <= 5 ? 2 : 3);
  final dist = _levenshtein(queryLower, cityLower);
  if (dist <= maxDist) return 100 + dist;

  // Prefix of city within edit distance (e.g. "patn" → "patna").
  if (cityLower.length >= queryLower.length) {
    final prefix = cityLower.substring(0, queryLower.length);
    final pDist = _levenshtein(queryLower, prefix);
    if (pDist <= maxDist) return 50 + pDist;
  }
  return -1;
}

/// Ranked fuzzy suggestions for typed text (typos like "patn" → Patna).
List<String> fuzzySuggestCities(String query, {int limit = 16}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return kSuggestedCities.take(limit).toList();
  }

  final scored = <({String name, int score})>[];
  final seen = <String>{};

  void consider(String name, int score) {
    if (score < 0 || seen.contains(name)) return;
    seen.add(name);
    scored.add((name: name, score: score));
  }

  for (final city in kIndiaCities) {
    consider(city.name, _fuzzyScore(q, city.name.toLowerCase()));
  }
  for (final entry in _canonicalByLower.entries) {
    if (entry.key == entry.value.toLowerCase()) continue;
    final score = _fuzzyScore(q, entry.key);
    if (score < 0) continue;
    consider(entry.value, score + 5);
  }

  scored.sort((a, b) {
    final byScore = a.score.compareTo(b.score);
    if (byScore != 0) return byScore;
    return a.name.compareTo(b.name);
  });
  return scored.take(limit).map((s) => s.name).toList();
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

double _rad(double deg) => deg * math.pi / 180.0;

/// Nearest curated city to a GPS point.
IndiaCity nearestCuratedCity(double lat, double lng) {
  IndiaCity best = kIndiaCities.first;
  var bestKm = double.infinity;
  for (final city in kIndiaCities) {
    final km = _haversineKm(lat, lng, city.lat, city.lng);
    if (km < bestKm) {
      bestKm = km;
      best = city;
    }
  }
  return best;
}

/// Resolve a GPS placemark to a display city without snapping to nearest mega-city.
///
/// Prefers the most specific reverse-geocode label (locality first). If that
/// label is a curated city / alias, returns the canonical name; otherwise keeps
/// the reverse-geocode text. Does not jump to a farther curated mega-city.
String? cityFromPlacemarkLabels({
  String? locality,
  String? subLocality,
  String? subAdministrativeArea,
  String? administrativeArea,
  String? name,
}) {
  for (final raw in [locality, subAdministrativeArea, subLocality, name]) {
    final cleaned = cleanPlaceLabel(raw);
    if (cleaned == null) continue;
    // Exact / alias / "Bangalore Urban" only — no fuzzy (avoids Keoti→Kochi).
    return _exactCuratedFromLabel(cleaned) ?? cleaned;
  }
  // Last resort among placemark fields: curated match on admin area only
  // (e.g. "Goa"), never a free-form state name like "Bihar".
  final admin = cleanPlaceLabel(administrativeArea);
  if (admin == null) return null;
  return _exactCuratedFromLabel(admin);
}

/// Exact / alias curated match for one label (no fuzzy edit-distance).
String? _exactCuratedFromLabel(String label) {
  final direct = resolveCuratedCity(label);
  if (direct != null) return direct;

  for (final word in label.split(RegExp(r'\s+'))) {
    final fromWord = resolveCuratedCity(word);
    if (fromWord != null) return fromWord;
  }

  final lower = label.trim().toLowerCase();
  for (final entry in _canonicalByLower.entries) {
    if (lower == entry.key ||
        lower.startsWith('${entry.key} ') ||
        lower.contains(' ${entry.key} ') ||
        lower.endsWith(' ${entry.key}')) {
      return entry.value;
    }
  }
  return null;
}

/// Map free-form place labels (reverse geocode) onto a curated city.
String? matchPlaceToCuratedCity(Iterable<String?> labels) {
  for (final label in labels) {
    if (label == null || label.trim().isEmpty) continue;
    final parts = label.split(RegExp(r'[,/|]'));
    for (final part in parts) {
      final resolved = resolveCuratedCity(part);
      if (resolved != null) return resolved;

      // "Bangalore Urban", "North Delhi", etc.
      for (final word in part.trim().split(RegExp(r'\s+'))) {
        final fromWord = resolveCuratedCity(word);
        if (fromWord != null) return fromWord;
      }

      final lower = part.trim().toLowerCase();
      for (final entry in _canonicalByLower.entries) {
        if (lower == entry.key ||
            lower.startsWith('${entry.key} ') ||
            lower.contains(' ${entry.key} ') ||
            lower.endsWith(' ${entry.key}')) {
          return entry.value;
        }
      }
    }
    final suggestions = fuzzySuggestCities(label, limit: 1);
    if (suggestions.isEmpty) continue;
    final candidate = suggestions.first;
    final q = label.trim().toLowerCase();
    final c = candidate.toLowerCase();
    if (c == q || c.startsWith(q) || q.startsWith(c) || _levenshtein(q, c) <= 2) {
      return candidate;
    }
  }
  return null;
}
