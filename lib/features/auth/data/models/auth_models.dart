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

  UserResponseDto({
    required this.userID,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.userType,
    this.avatarUrl,
  });

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserResponseDtoFromJson(json);
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiry;
  final UserResponseDto user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final expiryRaw = json['accessTokenExpiry'];
    DateTime expiry;
    if (expiryRaw is String) {
      expiry = DateTime.tryParse(expiryRaw) ??
          DateTime.now().toUtc().add(const Duration(hours: 1));
    } else {
      expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
    }
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiry: expiry,
      user: UserResponseDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
