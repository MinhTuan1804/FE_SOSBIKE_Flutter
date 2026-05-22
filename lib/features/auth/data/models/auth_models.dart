import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String phoneNumber;
  final String password;

  LoginRequest({required this.phoneNumber, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class UserResponseDto {
  final String userID;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String userType;
  final String? avatarUrl;
  final bool isPhoneVerified;
  final bool isActive;
  final String? gender;
  final String? dateOfBirth;

  UserResponseDto({
    required this.userID,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.userType,
    this.avatarUrl,
    this.isPhoneVerified = false,
    this.isActive = false,
    this.gender,
    this.dateOfBirth,
  });

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      userID: json['userID'] ?? json['userid'] ?? '',
      fullName: json['fullName'] ?? json['fullname'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phonenumber'] ?? '',
      email: json['email'],
      userType: json['userType'] ?? json['usertype'] ?? 'CUSTOMER',
      avatarUrl: json['avatarUrl'] ?? json['avatarurl'],
      isPhoneVerified: json['isPhoneVerified'] ?? json['isphoneverified'] ?? false,
      isActive: json['isActive'] ?? json['isactive'] ?? false,
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] ?? json['dateofbirth'],
    );
  }
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final DateTime accessTokenExpiry;
  final UserResponseDto user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.accessTokenExpiry,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final expiryRaw = json['accessTokenExpiry'] ?? json['exp'];
    DateTime expiry;
    if (expiryRaw is String) {
      expiry = DateTime.tryParse(expiryRaw) ??
          DateTime.now().toUtc().add(const Duration(hours: 1));
    } else if (expiryRaw is int) {
      expiry = DateTime.fromMillisecondsSinceEpoch(expiryRaw * 1000);
    } else {
      expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
    }
    return AuthResponse(
      accessToken: (json['accessToken'] ?? json['token']) as String,
      refreshToken: json['refreshToken'] as String?,
      accessTokenExpiry: expiry,
      user: UserResponseDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
