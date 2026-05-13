import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(message: "Kết nối quá hạn");
      case DioExceptionType.sendTimeout:
        return ApiException(message: "Gửi yêu cầu quá hạn");
      case DioExceptionType.receiveTimeout:
        return ApiException(message: "Nhận dữ liệu quá hạn");
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String msg = "Lỗi hệ thống ($statusCode)";
        if (data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return ApiException(message: msg, statusCode: statusCode);
      case DioExceptionType.cancel:
        return ApiException(message: "Yêu cầu bị hủy");
      default:
        return ApiException(message: "Đã xảy ra lỗi không xác định");
    }
  }
}
