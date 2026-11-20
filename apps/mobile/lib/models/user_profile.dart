class UserProfile {
  UserProfile({
    required this.id,
    required this.phone,
    this.displayName,
    required this.language,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.verificationStatus,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final String id;
  final String phone;
  final String? displayName;
  final String language;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? verificationStatus;
  final double ratingAvg;
  final int ratingCount;

  bool get hasRating => ratingCount > 0;

  bool get hasEmergencyContact =>
      emergencyContactName != null &&
      emergencyContactName!.trim().isNotEmpty &&
      emergencyContactPhone != null &&
      emergencyContactPhone!.trim().isNotEmpty;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse(v.toString());
    }

    double asDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String,
      displayName: json['displayName'] as String?,
      language: json['language'] as String? ?? 'en',
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
      ratingAvg: asDouble(json['ratingAvg']),
      ratingCount: asInt(json['ratingCount']) ?? 0,
    );
  }
}
