import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: LoginRequest(username: username, password: password).toJson(),
      );
      
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
