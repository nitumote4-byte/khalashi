class BookingRatingState {
  BookingRatingState({
    required this.bookingId,
    required this.tripId,
    required this.canRate,
    required this.rateeId,
    this.rateeDisplayName,
    this.myRating,
  });

  final String bookingId;
  final String tripId;
  final bool canRate;
  final String rateeId;
  final String? rateeDisplayName;
  final TripRating? myRating;

  factory BookingRatingState.fromJson(Map<String, dynamic> json) {
    return BookingRatingState(
      bookingId: json['bookingId'] as String,
      tripId: json['tripId'] as String,
      canRate: json['canRate'] as bool? ?? false,
      rateeId: json['rateeId'] as String,
      rateeDisplayName: json['rateeDisplayName'] as String?,
      myRating: json['myRating'] is Map<String, dynamic>
          ? TripRating.fromJson(json['myRating'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TripRating {
  TripRating({
    required this.id,
    required this.tripId,
    required this.bookingId,
    required this.raterId,
    required this.rateeId,
    required this.stars,
    this.comment,
  });

  final String id;
  final String tripId;
  final String bookingId;
  final String raterId;
  final String rateeId;
  final int stars;
  final String? comment;

  factory TripRating.fromJson(Map<String, dynamic> json) {
    return TripRating(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      bookingId: json['bookingId'] as String,
      raterId: json['raterId'] as String,
      rateeId: json['rateeId'] as String,
      stars: json['stars'] as int,
      comment: json['comment'] as String?,
    );
  }
}

enum ReportReason {
  harassment,
  unsafeDriving,
  noShow,
  spam,
  fraud,
  other;

  String get apiValue => switch (this) {
        ReportReason.harassment => 'harassment',
        ReportReason.unsafeDriving => 'unsafe_driving',
        ReportReason.noShow => 'no_show',
        ReportReason.spam => 'spam',
        ReportReason.fraud => 'fraud',
        ReportReason.other => 'other',
      };
}

class BlockedUser {
  BlockedUser({
    required this.blockedUserId,
    this.displayName,
    this.phone,
    required this.createdAt,
  });

  final String blockedUserId;
  final String? displayName;
  final String? phone;
  final DateTime createdAt;

  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    return phone ?? blockedUserId;
  }

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      blockedUserId: json['blockedUserId'] as String,
      displayName: json['displayName'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
