import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/suggested_cities.dart';

enum CityLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class CityLocationException implements Exception {
  CityLocationException(this.failure, [this.cause]);

  final CityLocationFailure failure;
  final Object? cause;

  @override
  String toString() => 'CityLocationException($failure)';
}

/// Result of resolving the device's current place for From/To.
class CityLocationResult {
  const CityLocationResult({
    required this.name,
    required this.fromReverseGeocode,
  });

  /// Display name to put in the field.
  final String name;

  /// True when [name] came from reverse-geocode (may be non-curated).
  final bool fromReverseGeocode;
}

/// GPS → reverse-geocode locality (prefer accurate place over nearest mega-city).
class CityLocationService {
  /// Resolves the device's current position to a city/locality name.
  ///
  /// Preference order:
  /// 1. Reverse-geocode label that matches a curated city (aliases OK)
  /// 2. Reverse-geocode locality / subAdministrativeArea / subLocality as-is
  /// 3. Nearest curated city by coordinates (last resort only)
  Future<CityLocationResult> resolveCurrentCity() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw CityLocationException(CityLocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw CityLocationException(CityLocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw CityLocationException(CityLocationFailure.permissionDeniedForever);
    }

    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      throw CityLocationException(CityLocationFailure.unavailable, e);
    }

    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final city = cityFromPlacemarkLabels(
          locality: p.locality,
          subLocality: p.subLocality,
          subAdministrativeArea: p.subAdministrativeArea,
          administrativeArea: p.administrativeArea,
          name: p.name,
        );
        if (city != null) {
          return CityLocationResult(name: city, fromReverseGeocode: true);
        }
      }
    } catch (_) {
      // Fall through to nearest curated city by coordinates.
    }

    return CityLocationResult(
      name: nearestCuratedCity(position.latitude, position.longitude).name,
      fromReverseGeocode: false,
    );
  }
}
