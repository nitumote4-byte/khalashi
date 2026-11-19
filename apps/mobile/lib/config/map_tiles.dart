/// Free map tiles for the pin picker (no Google Maps / paid key required).
///
/// Default: Esri World Street Map (raster, no API key). Carto’s public
/// `basemaps.cartocdn.com` CDN now serves watermark stubs (nearly blank tiles
/// with an “API key” mark) instead of real map imagery, which made Offer Ride
/// look empty on Android.
///
/// Optional override for a provider you already have a key for:
///
/// ```
/// flutter run --dart-define=MAP_TILE_URL_TEMPLATE=https://…/{z}/{x}/{y}.png
/// ```
///
/// Leave unset to use the free default below. Do **not** paste a MapTiler /
/// Stadia URL with a placeholder key — those providers return error tiles.
class MapTiles {
  MapTiles._();

  /// Optional override. Empty → [defaultUrlTemplate].
  static const String _override = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: '',
  );

  /// Esri World Street Map. Template uses `{z}/{y}/{x}` (ArcGIS tile order).
  static const String defaultUrlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

  /// OSM raster fallback when the primary URL fails (needs a proper User-Agent).
  static const String fallbackUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String get urlTemplate =>
      _override.trim().isEmpty ? defaultUrlTemplate : _override.trim();

  /// OSM fallback only when using the built-in Esri default (not a custom URL).
  static String? get fallbackUrl =>
      _override.trim().isEmpty ? fallbackUrlTemplate : null;

  /// Only used when the override still has `{s}` (rare). Esri/OSM need none.
  static List<String> get subdomains => const <String>[];

  /// Must match Android `applicationId` / iOS bundle id for OSM tile policy.
  static const String userAgentPackageName =
      'com.nitinmote.khalashi.khalashi';

  static const String attribution =
      '© Esri © OpenStreetMap contributors';
}
