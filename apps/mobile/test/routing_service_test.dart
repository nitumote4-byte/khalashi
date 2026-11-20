import 'package:flutter_test/flutter_test.dart';
import 'package:khalashi/services/routing_service.dart';

void main() {
  test('haversine Patna→Kolkata is roughly 470–500 km crow-flies', () {
    final m = RoutingService.haversineMeters(
      25.5941,
      85.1376,
      22.5726,
      88.3639,
    );
    final km = m / 1000;
    expect(km, greaterThan(450));
    expect(km, lessThan(520));
  });

  test('fallback route inflates distance and returns two-point polyline', () {
    final route = RoutingService.fallbackRoute(
      fromLat: 25.5941,
      fromLng: 85.1376,
      toLat: 22.5726,
      toLng: 88.3639,
    );
    expect(route.fromOsrm, isFalse);
    expect(route.points.length, 2);
    expect(route.distanceMeters, greaterThan(450000));
    expect(route.durationSeconds, greaterThan(60));
  });
}
