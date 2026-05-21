import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';

/// Lấy nội dung lỗi ngắn gọn từ BE / Dio để hiển thị SnackBar.
String errorMessageFrom(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    return ApiException.fromDioError(error).message;
  }
  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}
