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
    await store.addRecentCity('pune'); // should move Pune casing to front as 'pune'

    var cities = await store.getRecentCities();
    expect(cities.first, 'pune');
    expect(cities.where((c) => c.toLowerCase() == 'pune').length, 1);
    expect(cities.contains('Mumbai'), isTrue);

    for (var i = 0; i < 12; i++) {
      await store.addRecentCity('City$i');
    }
    cities = await store.getRecentCities();
    expect(cities.length, SessionStore.recentCitiesLimit);
    expect(cities.first, 'City11');
    expect(cities.contains('City0'), isFalse);
  });

  test('addRecentCities records both From and To with destination newest', () async {
    final store = SessionStore();
    await store.addRecentCities(['Pune', 'Mumbai']);
    final cities = await store.getRecentCities();
    expect(cities.take(2).toList(), ['Mumbai', 'Pune']);
  });
}
