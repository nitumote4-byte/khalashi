import 'package:flutter_test/flutter_test.dart';
import 'package:khalashi/data/suggested_cities.dart';

void main() {
  test('resolveCuratedCity accepts exact and alias names', () {
    expect(resolveCuratedCity('patna'), 'Patna');
    expect(resolveCuratedCity('  Pune '), 'Pune');
    expect(resolveCuratedCity('bangalore'), 'Bengaluru');
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

  test('nearestCuratedCity maps GPS near Patna', () {
    // Roughly Patna railway station area.
    final city = nearestCuratedCity(25.6093, 85.1376);
    expect(city.name, 'Patna');
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
  });
}
