import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/trip.dart';
import '../models/trust.dart';
import '../models/user_profile.dart';
import '../models/verification.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    required this.sessionStore,
    this.baseUrl = ApiConfig.baseUrl,
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
    String? pickupPoint,
    String? dropoffPoint,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    int? distanceMeters,
    int? durationSeconds,
    required DateTime departAt,
    required int seatsTotal,
    required int fareInr,
    required String carModel,
    required String numberPlate,
    required String carColor,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: await _headers(),
      body: jsonEncode({
        'origin': origin,
        'destination': destination,
        if (pickupPoint != null && pickupPoint.isNotEmpty) 'pickupPoint': pickupPoint,
        if (dropoffPoint != null && dropoffPoint.isNotEmpty) 'dropoffPoint': dropoffPoint,
        if (pickupLat != null) 'pickupLat': pickupLat,
        if (pickupLng != null) 'pickupLng': pickupLng,
        if (dropoffLat != null) 'dropoffLat': dropoffLat,
        if (dropoffLng != null) 'dropoffLng': dropoffLng,
        if (distanceMeters != null) 'distanceMeters': distanceMeters,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        'departAt': departAt.toUtc().toIso8601String(),
        'seatsTotal': seatsTotal,
        'fareInr': fareInr,
        'carModel': carModel,
        'numberPlate': numberPlate,
        'carColor': carColor,
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

  Future<UserProfile> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    return UserProfile.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateEmergencyContact({
    String? name,
    String? phone,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/auth/emergency-contact'),
      headers: await _headers(),
      body: jsonEncode({
        'emergencyContactName': name,
        'emergencyContactPhone': phone,
      }),
    );
    final body = await _decode(res);
    return UserProfile.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<void> logSos({
    required String tripId,
    String? bookingId,
    String action = 'pressed',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sos'),
      headers: await _headers(),
      body: jsonEncode({
        'tripId': tripId,
        if (bookingId != null) 'bookingId': bookingId,
        'action': action,
      }),
    );
    await _decode(res);
  }

  Future<VerificationInfo> getVerification() async {
    final res = await http.get(
      Uri.parse('$baseUrl/verification/me'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    return VerificationInfo.fromJson(
      body['verification'] as Map<String, dynamic>,
    );
  }

  Future<VerificationStatus> getVerificationStatus() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    final user = body['user'] as Map<String, dynamic>?;
    return VerificationStatusX.fromApi(user?['verificationStatus']?.toString());
  }

  Future<VerificationInfo> submitVerification({
    required IdType idType,
    required String fullName,
    required String idNumber,
    required String imageBase64,
    required String selfieBase64,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verification/submit'),
      headers: await _headers(),
      body: jsonEncode({
        'idType': idType.apiValue,
        'fullName': fullName,
        'idNumber': idNumber,
        'imageBase64': imageBase64,
        'selfieBase64': selfieBase64,
      }),
    );
    final body = await _decode(res);
    return VerificationInfo.fromJson(
      body['verification'] as Map<String, dynamic>,
    );
  }

  Future<BookingRatingState> getBookingRating(String bookingId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/ratings/booking/$bookingId'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    return BookingRatingState.fromJson(body);
  }

  Future<TripRating> submitRating({
    required String bookingId,
    required int stars,
    String? comment,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: await _headers(),
      body: jsonEncode({
        'bookingId': bookingId,
        'stars': stars,
        if (comment != null) 'comment': comment,
      }),
    );
    final body = await _decode(res);
    return TripRating.fromJson(body['rating'] as Map<String, dynamic>);
  }

  Future<void> reportUser({
    required String reportedUserId,
    required ReportReason reason,
    String? details,
    String? tripId,
    String? bookingId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: await _headers(),
      body: jsonEncode({
        'reportedUserId': reportedUserId,
        'reason': reason.apiValue,
        if (details != null) 'details': details,
        if (tripId != null) 'tripId': tripId,
        if (bookingId != null) 'bookingId': bookingId,
      }),
    );
    await _decode(res);
  }

  Future<void> blockUser(String userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/blocks'),
      headers: await _headers(),
      body: jsonEncode({'userId': userId}),
    );
    await _decode(res);
  }

  Future<void> unblockUser(String userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/blocks/$userId'),
      headers: await _headers(),
    );
    await _decode(res);
  }

  Future<List<BlockedUser>> myBlocks() async {
    final res = await http.get(
      Uri.parse('$baseUrl/blocks/mine'),
      headers: await _headers(),
    );
    final body = await _decode(res);
    final list = body['blocks'] as List<dynamic>;
    return list
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
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
