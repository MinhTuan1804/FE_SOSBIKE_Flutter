import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';

class SendOtpResult {
  const SendOtpResult({
    required this.message,
    required this.expiresInSeconds,
    this.debugCode,
  });

  final String message;
  final int expiresInSeconds;
  final String? debugCode;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.otpToken,
    required this.expiresInSeconds,
  });

  final String otpToken;
  final int expiresInSeconds;
}

/// OTP đăng ký qua API SOSbike (SMS ESMS / log dev).
class BackendOtpService {
  BackendOtpService(this._dioClient);

  final DioClient _dioClient;

  Dio get _dio => _dioClient.dio;

  Future<SendOtpResult> sendOtp(String phoneNumber, {String purpose = 'register'}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.sendOtp,
        data: {
          'phoneNumber': phoneNumber,
          'purpose': purpose,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return SendOtpResult(
        message: data['message'] as String? ?? 'Đã gửi mã OTP.',
        expiresInSeconds: data['expiresInSeconds'] as int? ?? 300,
        debugCode: data['debugCode'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VerifyOtpResult> verifyOtp(String phoneNumber, String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return VerifyOtpResult(
        otpToken: data['otpToken'] as String,
        expiresInSeconds: data['expiresInSeconds'] as int? ?? 900,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
