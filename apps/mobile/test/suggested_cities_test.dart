import 'package:flutter_test/flutter_test.dart';
import 'package:khalashi/data/suggested_cities.dart';

void main() {
  test('resolveCuratedCity accepts exact and alias names', () {
    expect(resolveCuratedCity('patna'), 'Patna');
    expect(resolveCuratedCity('  Pune '), 'Pune');
    expect(resolveCuratedCity('bangalore'), 'Bengaluru');
    expect(resolveCuratedCity('darbhanga'), 'Darbhanga');
    expect(resolveCuratedCity('patn'), isNull);
    expect(resolveCuratedCity(''), isNull);
  });

  test('fuzzySuggestCities ranks typo patn toward Patna', () {
    final hits = fuzzySuggestCities('patn');
    expect(hits, isNotEmpty);
    expect(hits.first, 'Patna');
  });

  test('fuzzySuggestCities finds prefix matches', () {
    final hits = fuzzySuggestCities('mum');
    expect(hits.first, 'Mumbai');
  });

  test('fuzzySuggestCities finds Darbhanga', () {
    final hits = fuzzySuggestCities('darb');
    expect(hits.first, 'Darbhanga');
  });

  test('nearestCuratedCity maps GPS near Patna', () {
    // Roughly Patna railway station area.
    final city = nearestCuratedCity(25.6093, 85.1376);
    expect(city.name, 'Patna');
  });

  test('nearestCuratedCity maps GPS near Darbhanga', () {
    final city = nearestCuratedCity(26.1542, 85.8918);
    expect(city.name, 'Darbhanga');
  });

  test('matchPlaceToCuratedCity uses locality labels', () {
    expect(
      matchPlaceToCuratedCity(['Patna', 'Bihar', 'India']),
      'Patna',
    );
    expect(
      matchPlaceToCuratedCity(['Bangalore Urban', 'Karnataka']),
      'Bengaluru',
    );
    expect(
      matchPlaceToCuratedCity(['Darbhanga', 'Bihar', 'India']),
      'Darbhanga',
    );
  });

  test('cityFromPlacemarkLabels prefers reverse-geocode locality over nearest snap', () {
    // Darbhanga locality must win even though Patna is a curated mega-city.
    expect(
      cityFromPlacemarkLabels(
        locality: 'Darbhanga',
        subAdministrativeArea: 'Darbhanga',
        administrativeArea: 'Bihar',
      ),
      'Darbhanga',
    );
    // Unknown locality is kept as-is (not snapped to curated district/mega-city).
    expect(
      cityFromPlacemarkLabels(
        locality: 'Keoti',
        subAdministrativeArea: 'Darbhanga',
        administrativeArea: 'Bihar',
      ),
      'Keoti',
    );
    // No locality → use district (subAdministrativeArea), not state.
    expect(
      cityFromPlacemarkLabels(
        locality: null,
        subAdministrativeArea: 'Muzaffarpur',
        administrativeArea: 'Bihar',
      ),
      'Muzaffarpur',
    );
    // Bangalore alias still canonicalizes.
    expect(
      cityFromPlacemarkLabels(locality: 'Bangalore'),
      'Bengaluru',
    );
    // State alone is not a city.
    expect(
      cityFromPlacemarkLabels(administrativeArea: 'Bihar'),
      isNull,
    );
  });

  test('resolveTripCity accepts curated or GPS-accepted places', () {
    expect(resolveTripCity('Patna'), 'Patna');
    expect(resolveTripCity('keoti'), isNull);
    expect(
      resolveTripCity('keoti', gpsAcceptedLower: {'keoti'}),
      'Keoti',
    );
    expect(
      resolveTripCity('patn', gpsAcceptedLower: {'keoti'}),
      isNull,
    );
  });
}
