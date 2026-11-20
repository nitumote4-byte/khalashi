class UserProfile {
  UserProfile({
    required this.id,
    required this.phone,
    this.displayName,
    required this.language,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.verificationStatus,
  });

  final String id;
  final String phone;
  final String? displayName;
  final String language;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? verificationStatus;

  bool get hasEmergencyContact =>
      emergencyContactName != null &&
      emergencyContactName!.trim().isNotEmpty &&
      emergencyContactPhone != null &&
      emergencyContactPhone!.trim().isNotEmpty;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String,
      displayName: json['displayName'] as String?,
      language: json['language'] as String? ?? 'en',
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
    );
  }
}
