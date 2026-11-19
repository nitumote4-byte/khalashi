/// Free map tiles for the pin picker (no Google Maps / paid key required).
///
/// Default: Carto Voyager via cartocdn (OSM data). Fine for local/dev and soft
/// launch; for heavier production traffic, set a MapTiler (or similar) URL:
///
/// ```
/// flutter run --dart-define=MAP_TILE_URL_TEMPLATE=https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=YOUR_KEY
/// ```
///
/// Leave unset to use the free Carto template below (no placeholder key needed).
class MapTiles {
  MapTiles._();

  /// Optional override. Empty → [defaultUrlTemplate].
  static const String _override = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: '',
  );

  /// Soft, modern light basemap (Carto Voyager). No API key.
  static const String defaultUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  static const List<String> defaultSubdomains = ['a', 'b', 'c', 'd'];

  static String get urlTemplate =>
      _override.trim().isEmpty ? defaultUrlTemplate : _override.trim();

  /// Subdomains only apply to the default Carto template.
  static List<String> get subdomains =>
      _override.trim().isEmpty ? defaultSubdomains : const <String>[];

  static const String userAgentPackageName = 'com.khalashi.app';

  static const String attribution =
      '© OpenStreetMap contributors © CARTO';
}
