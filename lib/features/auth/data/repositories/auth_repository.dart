import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> login(String phoneNumber, String password) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: LoginRequest(phoneNumber: phoneNumber, password: password).toJson(),
      );
      
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> firebaseLogin(String idToken, {String? fullName, String? userType}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.firebaseLogin,
        data: {
          'idToken': idToken,
          if (fullName != null) 'fullName': fullName,
          if (userType != null) 'userType': userType,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String userType,
    String? email,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.register,
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
          'fullName': fullName,
          'userType': userType,
          if (email != null) 'email': email,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
