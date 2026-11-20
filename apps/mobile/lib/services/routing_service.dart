import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Driving route between two WGS84 points (polyline + distance + duration).
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.fromOsrm,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final bool fromOsrm;

  double get distanceKm => distanceMeters / 1000.0;
}

/// Free OSRM public API with straight-line / haversine fallback (no paid key).
class RoutingService {
  RoutingService({
    this.baseUrl = 'https://router.project-osrm.org',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Average speed used for duration when OSRM is unavailable (~45 km/h).
  static const double _fallbackSpeedMps = 45.0 * 1000.0 / 3600.0;

  Future<RouteResult> route({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/route/v1/driving/'
        '${fromLng.toStringAsFixed(6)},${fromLat.toStringAsFixed(6)};'
        '${toLng.toStringAsFixed(6)},${toLat.toStringAsFixed(6)}'
        '?overview=full&geometries=geojson',
      );
      final res = await _client
          .get(uri, headers: {'User-Agent': 'khalashi-mobile/0.1'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['code'] == 'Ok') {
          final routes = body['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final route = routes.first as Map<String, dynamic>;
            final distance = (route['distance'] as num).toDouble();
            final duration = (route['duration'] as num).round();
            final geometry = route['geometry'] as Map<String, dynamic>?;
            final coords = geometry?['coordinates'] as List<dynamic>?;
            if (coords != null && coords.length >= 2) {
              final points = <LatLng>[];
              for (final c in coords) {
                final pair = c as List<dynamic>;
                points.add(
                  LatLng(
                    (pair[1] as num).toDouble(),
                    (pair[0] as num).toDouble(),
                  ),
                );
              }
              return RouteResult(
                points: points,
                distanceMeters: distance,
                durationSeconds: duration,
                fromOsrm: true,
              );
            }
          }
        }
      }
    } catch (_) {
      // Fall through to estimate.
    }
    return fallbackRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  /// Straight-line polyline + haversine distance + speed-based duration.
  static RouteResult fallbackRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final meters = haversineMeters(fromLat, fromLng, toLat, toLng);
    // Roads are longer than crow-flies; inflate ~20% for a rough estimate.
    final roadMeters = meters * 1.2;
    final duration = math.max(60, (roadMeters / _fallbackSpeedMps).round());
    return RouteResult(
      points: [LatLng(fromLat, fromLng), LatLng(toLat, toLng)],
      distanceMeters: roadMeters,
      durationSeconds: duration,
      fromOsrm: false,
    );
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
