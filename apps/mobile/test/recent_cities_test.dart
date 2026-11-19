import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khalashi/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addRecentCity prepends, dedupes case-insensitively, and caps at 10', () async {
    final store = SessionStore();

    await store.addRecentCity('Pune');
    await store.addRecentCity('Mumbai');
    await store.addRecentCity('pune'); // canonical 'Pune' moves to front

    var cities = await store.getRecentCities();
    expect(cities.first, 'Pune');
    expect(cities.where((c) => c.toLowerCase() == 'pune').length, 1);
    expect(cities.contains('Mumbai'), isTrue);

    final extras = [
      'Delhi',
      'Patna',
      'Jaipur',
      'Chennai',
      'Kolkata',
      'Hyderabad',
      'Ahmedabad',
      'Surat',
      'Indore',
      'Nagpur',
      'Lucknow',
      'Kanpur',
    ];
    for (final city in extras) {
      await store.addRecentCity(city);
    }
    cities = await store.getRecentCities();
    expect(cities.length, SessionStore.recentCitiesLimit);
    expect(cities.first, 'Kanpur');
    expect(cities.contains('Pune'), isFalse);
  });

  test('addRecentCities records both From and To with destination newest', () async {
    final store = SessionStore();
    await store.addRecentCities(['Pune', 'Mumbai']);
    final cities = await store.getRecentCities();
    expect(cities.take(2).toList(), ['Mumbai', 'Pune']);
  });

  test('ignores free-text and drops legacy non-curated recents', () async {
    SharedPreferences.setMockInitialValues({
      'khalashi_recent_cities': <String>['patn', 'Pune', 'somewhere'],
    });
    final store = SessionStore();
    expect(await store.getRecentCities(), ['Pune']);

    await store.addRecentCity('patn');
    expect(await store.getRecentCities(), ['Pune']);
  });
}
