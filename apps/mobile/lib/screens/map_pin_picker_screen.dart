import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_tiles.dart';
import '../data/suggested_cities.dart';
import '../l10n/app_localizations.dart';
import '../models/meeting_point.dart';
import '../theme/khalashi_theme.dart';

/// BlaBlaCar-style full-screen map: pan under a fixed center pin, then confirm.
class MapPinPickerScreen extends StatefulWidget {
  const MapPinPickerScreen({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initial,
    this.hintCity,
  });

  final String title;
  final String confirmLabel;
  final MeetingPoint? initial;

  /// City name used to center the map when [initial] is null.
  final String? hintCity;

  @override
  State<MapPinPickerScreen> createState() => _MapPinPickerScreenState();
}

class _MapPinPickerScreenState extends State<MapPinPickerScreen> {
  static const _fallback = LatLng(25.5941, 85.1376); // Patna
  static const _defaultZoom = 14.0;

  late final MapController _mapController;
  late LatLng _center;
  String? _addressLabel;
  bool _geocoding = false;
  bool _moving = false;
  bool _tilesFailed = false;
  int _tileLayerGeneration = 0;
  int _tileErrorCount = 0;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = _resolveInitialCenter();
    _addressLabel = widget.initial?.label;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_center);
    });
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  LatLng _resolveInitialCenter() {
    final initial = widget.initial;
    if (initial != null) {
      return LatLng(initial.lat, initial.lng);
    }
    final hint = widget.hintCity?.trim();
    if (hint != null && hint.isNotEmpty) {
      final city = lookupCuratedCity(hint);
      if (city != null) return LatLng(city.lat, city.lng);
    }
    return _fallback;
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final next = camera.center;
    if (_center.latitude == next.latitude &&
        _center.longitude == next.longitude) {
      return;
    }
    setState(() {
      _center = next;
      _moving = hasGesture;
    });
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _moving = false);
      _reverseGeocode(next);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _geocoding = true);
    try {
      final places = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      final label = places.isEmpty
          ? _coordFallback(point)
          : _formatPlacemark(places.first, point);
      setState(() {
        _addressLabel = label;
        _geocoding = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressLabel = _coordFallback(point);
        _geocoding = false;
      });
    }
  }

  String _coordFallback(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

  String _formatPlacemark(Placemark p, LatLng point) {
    final parts = <String>[
      if ((p.name ?? '').trim().isNotEmpty &&
          p.name != p.street &&
          p.name != p.locality)
        p.name!.trim(),
      if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
      if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
      if ((p.subAdministrativeArea ?? '').trim().isNotEmpty &&
          p.subAdministrativeArea != p.locality)
        p.subAdministrativeArea!.trim(),
    ];
    final unique = <String>[];
    for (final part in parts) {
      if (unique.any((u) => u.toLowerCase() == part.toLowerCase())) continue;
      unique.add(part);
    }
    if (unique.isEmpty) return _coordFallback(point);
    return unique.take(3).join(', ');
  }

  Future<void> _goToMyLocation() async {
    final l10n = AppLocalizations.of(context);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _toast(l10n.locationServiceDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _toast(l10n.locationPermissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _toast(l10n.locationPermissionDeniedForever);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController.move(target, _defaultZoom);
      setState(() => _center = target);
      await _reverseGeocode(target);
    } catch (_) {
      _toast(l10n.locationUnavailable);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    _tileErrorCount++;
    // A few misses are normal while panning; a burst means the basemap is down.
    if (_tileErrorCount < 4 || _tilesFailed) return;
    if (!mounted) return;
    setState(() => _tilesFailed = true);
  }

  void _retryTiles() {
    setState(() {
      _tilesFailed = false;
      _tileErrorCount = 0;
      _tileLayerGeneration++;
    });
  }

  void _confirm() {
    final label = (_addressLabel ?? _coordFallback(_center)).trim();
    Navigator.of(context).pop(
      MeetingPoint(
        lat: _center.latitude,
        lng: _center.longitude,
        label: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addressText = _moving
        ? l10n.mapPinMoving
        : (_addressLabel ?? (_geocoding ? l10n.mapPinLookingUp : '…'));

    return Scaffold(
      backgroundColor: KhalashiColors.dusk,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _defaultZoom,
              minZoom: 4,
              maxZoom: 18,
              onPositionChanged: _onPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                key: ValueKey('basemap-$_tileLayerGeneration'),
                urlTemplate: MapTiles.urlTemplate,
                fallbackUrl: MapTiles.fallbackUrl,
                subdomains: MapTiles.subdomains,
                userAgentPackageName: MapTiles.userAgentPackageName,
                // Esri/OSM templates have no `{r}`; simulated retina just
                // over-fetches zoom+1 and is unnecessary for pin picking.
                retinaMode: false,
                errorTileCallback: _onTileError,
                evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
              ),
            ],
          ),
          if (_tilesFailed)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 64,
              child: Material(
                color: Colors.white.withOpacity(0.96),
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: KhalashiColors.dusk,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.mapTilesUnavailable,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: KhalashiColors.dusk,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: _retryTiles,
                        child: Text(l10n.mapTilesRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Fixed center pin (map pans underneath).
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: _moving ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(
                        Icons.location_on,
                        size: 52,
                        color: KhalashiColors.saffron,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: KhalashiColors.dusk.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _ChromeButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: KhalashiColors.dusk,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ChromeButton(
                    icon: Icons.my_location,
                    onPressed: _goToMyLocation,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Material(
                  color: Colors.white.withOpacity(0.97),
                  elevation: 8,
                  shadowColor: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.mapPinHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: KhalashiColors.dusk.withOpacity(0.65),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: KhalashiColors.deepTeal,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                addressText,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: KhalashiColors.dusk),
                              ),
                            ),
                            if (_geocoding && !_moving)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _moving || _geocoding ? null : _confirm,
                          child: Text(widget.confirmLabel),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          MapTiles.attribution,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: KhalashiColors.dusk.withOpacity(0.45),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.94),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: KhalashiColors.dusk),
        ),
      ),
    );
  }
}
