enum VerificationStatus {
  unverified,
  pendingReview,
  verified,
  rejected,
}

enum IdType { aadhaar, dl, voter }

extension VerificationStatusX on VerificationStatus {
  String get apiValue {
    switch (this) {
      case VerificationStatus.unverified:
        return 'unverified';
      case VerificationStatus.pendingReview:
        return 'pending_review';
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.rejected:
        return 'rejected';
    }
  }

  static VerificationStatus fromApi(String? raw) {
    switch (raw) {
      case 'pending_review':
        return VerificationStatus.pendingReview;
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.unverified;
    }
  }

  /// Soft-gate: Offer Ride allowed once submitted (pending) or verified.
  bool get canOfferRide =>
      this == VerificationStatus.pendingReview || this == VerificationStatus.verified;
}

extension IdTypeX on IdType {
  String get apiValue {
    switch (this) {
      case IdType.aadhaar:
        return 'aadhaar';
      case IdType.dl:
        return 'dl';
      case IdType.voter:
        return 'voter';
    }
  }

  static IdType fromApi(String? raw) {
    switch (raw) {
      case 'dl':
        return IdType.dl;
      case 'voter':
        return IdType.voter;
      default:
        return IdType.aadhaar;
    }
  }
}

class VerificationInfo {
  const VerificationInfo({
    required this.status,
    this.idType,
    this.fullName,
    this.idNumberMasked,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
  });

  final VerificationStatus status;
  final IdType? idType;
  final String? fullName;
  final String? idNumberMasked;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  factory VerificationInfo.fromJson(Map<String, dynamic> json) {
    return VerificationInfo(
      status: VerificationStatusX.fromApi(json['status']?.toString()),
      idType: json['idType'] == null
          ? null
          : IdTypeX.fromApi(json['idType']?.toString()),
      fullName: json['fullName']?.toString(),
      idNumberMasked: json['idNumberMasked']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      reviewNote: json['reviewNote']?.toString(),
    );
  }

  static const unverified = VerificationInfo(status: VerificationStatus.unverified);
}
