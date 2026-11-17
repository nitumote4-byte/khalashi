import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    required this.sessionStore,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  });

  final SessionStore sessionStore;
  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await sessionStore.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || body['ok'] == false) {
      throw ApiException(
        body['error']?.toString() ?? 'Request failed',
        code: body['code']?.toString(),
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  Future<Trip> createTrip({
    required String origin,
    required String destination,
    required DateTime departAt,
    required int seatsTotal,
    required int fareInr,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: await _headers(),
      body: jsonEncode({
        'origin': origin,
        'destination': destination,
        'departAt': departAt.toUtc().toIso8601String(),
        'seatsTotal': seatsTotal,
        'fareInr': fareInr,
      }),
    );
    final body = await _decode(res);
    return Trip.fromJson(body['trip'] as Map<String, dynamic>);
  }

  Future<List<Trip>> myTrips() async {
    final res = await http.get(
      Uri.parse('$baseUrl/trips/mine'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    final list = body['trips'] as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Trip>> searchTrips({
    required String origin,
    required String destination,
    required String dateYmd,
  }) async {
    final uri = Uri.parse('$baseUrl/trips/search').replace(queryParameters: {
      'origin': origin,
      'destination': destination,
      'date': dateYmd,
    });
    final res = await http.get(uri, headers: await _headers());
    final body = await _decode(res);
    final list = body['trips'] as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trip> getTrip(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/trips/$id'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    return Trip.fromJson(body['trip'] as Map<String, dynamic>);
  }

  Future<Trip> cancelTrip(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trips/$id/cancel'),
      headers: await _headers(),
      body: '{}',
    );
    final body = await _decode(res);
    return Trip.fromJson(body['trip'] as Map<String, dynamic>);
  }

  Future<({Trip trip, List<Booking> bookings})> tripBookings(String tripId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/trips/$tripId/bookings'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    final trip = Trip.fromJson(body['trip'] as Map<String, dynamic>);
    final bookings = (body['bookings'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
    return (trip: trip, bookings: bookings);
  }

  Future<Booking> bookTrip({
    required String tripId,
    required int seats,
    required String seatPreference,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/bookings'),
      headers: await _headers(),
      body: jsonEncode({
        'seats': seats,
        'seatPreference': seatPreference,
      }),
    );
    final body = await _decode(res);
    return Booking.fromJson(body['booking'] as Map<String, dynamic>);
  }

  Future<List<Booking>> myBookings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/mine'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    final list = body['bookings'] as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> getBooking(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    return Booking.fromJson(body['booking'] as Map<String, dynamic>);
  }

  Future<Booking> cancelBooking(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/$id/cancel'),
      headers: await _headers(),
      body: '{}',
    );
    final body = await _decode(res);
    return Booking.fromJson(body['booking'] as Map<String, dynamic>);
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}
