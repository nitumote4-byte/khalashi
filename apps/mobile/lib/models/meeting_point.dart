/// Map-pin meeting spot chosen on Offer Ride (lat/lng + reverse-geocoded label).
class MeetingPoint {
  const MeetingPoint({
    required this.lat,
    required this.lng,
    required this.label,
  });

  final double lat;
  final double lng;
  final String label;

  MeetingPoint copyWith({double? lat, double? lng, String? label}) {
    return MeetingPoint(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
    );
  }
}
