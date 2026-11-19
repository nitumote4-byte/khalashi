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

/// GPS → reverse-geocode / nearest curated city.
class CityLocationService {
  /// Returns a canonical curated city name for the device's current position.
  Future<String> resolveCurrentCity() async {
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
        final matched = matchPlaceToCuratedCity([
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.subLocality,
          p.name,
        ]);
        if (matched != null) return matched;
      }
    } catch (_) {
      // Fall through to nearest curated city by coordinates.
    }

    return nearestCuratedCity(position.latitude, position.longitude).name;
  }
}
