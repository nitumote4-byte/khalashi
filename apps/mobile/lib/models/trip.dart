class Trip {
  Trip({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departAt,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.fareInr,
    required this.status,
    this.driverDisplayName,
    this.driverPhone,
  });

  final String id;
  final String driverId;
  final String origin;
  final String destination;
  final DateTime departAt;
  final int seatsTotal;
  final int seatsLeft;
  final int fareInr;
  final String status;
  final String? driverDisplayName;
  final String? driverPhone;

  bool get isFull => seatsLeft <= 0;
  bool get isOpen => status == 'open';
  bool get canBook => isOpen && seatsLeft > 0 && departAt.isAfter(DateTime.now());
  bool get canCancel => isOpen && departAt.isAfter(DateTime.now());

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      departAt: DateTime.parse(json['departAt'] as String).toLocal(),
      seatsTotal: json['seatsTotal'] as int,
      seatsLeft: json['seatsLeft'] as int,
      fareInr: json['fareInr'] as int,
      status: json['status'] as String,
      driverDisplayName: json['driverDisplayName'] as String?,
      driverPhone: json['driverPhone'] as String?,
    );
  }
}

class Booking {
  Booking({
    required this.id,
    required this.tripId,
    required this.travellerId,
    required this.seats,
    required this.seatPreference,
    required this.cashTotalInr,
    required this.status,
    required this.bookingRef,
    this.cancelledBy,
    this.cancelReason,
    this.travellerPhone,
    this.travellerDisplayName,
    this.trip,
  });

  final String id;
  final String tripId;
  final String travellerId;
  final int seats;
  final String seatPreference;
  final int cashTotalInr;
  final String status;
  final String bookingRef;
  final String? cancelledBy;
  final String? cancelReason;
  final String? travellerPhone;
  final String? travellerDisplayName;
  final Trip? trip;

  bool get isConfirmed => status == 'confirmed';
  bool get canCancel =>
      isConfirmed && (trip?.departAt.isAfter(DateTime.now()) ?? false);

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      travellerId: json['travellerId'] as String,
      seats: json['seats'] as int,
      seatPreference: json['seatPreference'] as String,
      cashTotalInr: json['cashTotalInr'] as int,
      status: json['status'] as String,
      bookingRef: json['bookingRef'] as String? ??
          (json['id'] as String).replaceAll('-', '').substring(0, 8).toUpperCase(),
      cancelledBy: json['cancelledBy'] as String?,
      cancelReason: json['cancelReason'] as String?,
      travellerPhone: json['travellerPhone'] as String?,
      travellerDisplayName: json['travellerDisplayName'] as String?,
      trip: json['trip'] is Map<String, dynamic>
          ? Trip.fromJson(json['trip'] as Map<String, dynamic>)
          : null,
    );
  }
}
