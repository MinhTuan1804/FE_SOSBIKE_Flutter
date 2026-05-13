// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  token: json['token'] as String,
  username: json['username'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'username': instance.username,
      'email': instance.email,
    };
