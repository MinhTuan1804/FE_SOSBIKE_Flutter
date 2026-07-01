import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';

/// Lấy nội dung lỗi ngắn gọn từ BE / Dio để hiển thị SnackBar.
String errorMessageFrom(Object error) {
  if (error is ApiException) return error.message;
  if (error is FirebaseException) {
    return error.message ?? 'Lỗi Firebase. Vui lòng thử lại.';
  }
  if (error is DioException) {
    return ApiException.fromDioError(error).message;
  }
  final text = error.toString();

  // Việt hóa các lỗi hệ thống / thư viện kết nối (SignalR, Socket, Timeout)
  if (text.contains('Server timeout elapsed') || text.contains('without receiving a message')) {
    return 'Hết thời gian chờ phản hồi từ máy chủ. Vui lòng tải lại.';
  }
  if (text.contains('SocketException') || text.contains('Connection failed') || text.contains('Network is unreachable')) {
    return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
  }
  if (text.contains('TimeoutException') || text.contains('timeout') || text.contains('elapsed')) {
    return 'Kết nối quá hạn hoặc không nhận được phản hồi.';
  }

  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}
