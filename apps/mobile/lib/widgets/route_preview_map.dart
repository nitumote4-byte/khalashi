import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_tiles.dart';
import '../l10n/app_localizations.dart';
import '../services/routing_service.dart';
import '../theme/khalashi_theme.dart';

/// Non-interactive map showing origin/destination markers and a route polyline.
class RoutePreviewMap extends StatefulWidget {
  const RoutePreviewMap({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
  });

  final RouteResult route;
  final LatLng origin;
  final LatLng destination;

  @override
  State<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<RoutePreviewMap> {
  late final MapController _mapController;
  bool _tilesFailed = false;
  int _tileLayerGeneration = 0;
  int _tileErrorCount = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void didUpdateWidget(covariant RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.points != widget.route.points) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds() {
    final pts = widget.route.points;
    if (pts.isEmpty || !mounted) return;
    var minLat = pts.first.latitude;
    var maxLat = pts.first.latitude;
    var minLng = pts.first.longitude;
    var maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    // Pad slightly so markers aren't on the edge.
    final latPad = mathMax((maxLat - minLat) * 0.15, 0.02);
    final lngPad = mathMax((maxLng - minLng) * 0.15, 0.02);
    final bounds = LatLngBounds(
      LatLng(minLat - latPad, minLng - lngPad),
      LatLng(maxLat + latPad, maxLng + lngPad),
    );
    try {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(28)),
      );
    } catch (_) {
      // Map may not be ready yet.
    }
  }

  double mathMax(double a, double b) => a > b ? a : b;

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    _tileErrorCount++;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.origin,
              initialZoom: 7,
              minZoom: 4,
              maxZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                key: ValueKey('route-basemap-$_tileLayerGeneration'),
                urlTemplate: MapTiles.urlTemplate,
                fallbackUrl: MapTiles.fallbackUrl,
                subdomains: MapTiles.subdomains,
                userAgentPackageName: MapTiles.userAgentPackageName,
                retinaMode: false,
                errorTileCallback: _onTileError,
                evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.route.points,
                    strokeWidth: 4.5,
                    color: KhalashiColors.deepTeal,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white.withOpacity(0.85),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.origin,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.trip_origin,
                      color: KhalashiColors.deepTeal,
                      size: 28,
                    ),
                  ),
                  Marker(
                    point: widget.destination,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: KhalashiColors.saffron,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_tilesFailed)
            Positioned(
              left: 10,
              right: 10,
              top: 10,
              child: Material(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.mapTilesUnavailable)),
                      TextButton(
                        onPressed: _retryTiles,
                        child: Text(l10n.mapTilesRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            bottom: 6,
            child: Text(
              MapTiles.attribution,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: KhalashiColors.dusk.withOpacity(0.55),
                    fontSize: 9,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
