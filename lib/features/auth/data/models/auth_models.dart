/// Authenticated User Representation
class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final bool isVerified;
  final String? devicePlatform;
  final String? createdAt;
  final String? referralCode;
  final String? inviteLink;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    this.isVerified = false,
    this.devicePlatform,
    this.createdAt,
    this.referralCode,
    this.inviteLink,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'patient',
      isVerified: json['is_verified'] == true,
      devicePlatform: json['device_platform']?.toString(),
      createdAt: json['created_at']?.toString(),
      referralCode: json['referral_code']?.toString(),
      inviteLink: json['invite_link']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'is_verified': isVerified,
      'device_platform': devicePlatform,
      'created_at': createdAt,
      'referral_code': referralCode,
      'invite_link': inviteLink,
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isClinicAdmin => role == 'clinic_admin';
  bool get isClinicStaff => role == 'clinic_staff';
  bool get isPatient => role == 'patient' || role.isEmpty;
}

/// Token & Session Response returned by /auth/login/ and /auth/verify-otp/
class AuthResponse {
  final String tokenType;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;

  const AuthResponse({
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : const UserModel(id: '', fullName: '', phone: '', role: 'patient'),
    );
  }
}

/// Response returned by /auth/register/
class RegisterResponse {
  final String userId;
  final String message;
  final String otpPurpose;
  final int expiresIn;

  const RegisterResponse({
    required this.userId,
    required this.message,
    required this.otpPurpose,
    required this.expiresIn,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['user_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      otpPurpose: json['otp_purpose']?.toString() ?? 'registration',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
    );
  }
}
