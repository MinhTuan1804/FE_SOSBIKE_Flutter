import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String token;
  final String? username;
  final String? email;

  AuthResponse({required this.token, this.username, this.email});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}
