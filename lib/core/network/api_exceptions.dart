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
        return ApiException(message: 'Kết nối quá hạn. Kiểm tra mạng hoặc BE local.');
      case DioExceptionType.sendTimeout:
        return ApiException(message: 'Gửi yêu cầu quá hạn');
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Nhận dữ liệu quá hạn');
      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Không kết nối được máy chủ (localhost:5200). Hãy chạy BE: dotnet run --launch-profile http',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final parsed = _parseResponseBody(data);
        final msg = parsed.isNotEmpty
            ? parsed
            : 'Lỗi máy chủ (mã $statusCode)';
        return ApiException(message: msg, statusCode: statusCode);
      case DioExceptionType.cancel:
        return ApiException(message: 'Yêu cầu bị hủy');
      default:
        return ApiException(message: 'Đã xảy ra lỗi không xác định');
    }
  }

  static String _parseResponseBody(dynamic data) {
    if (data is! Map) return '';

    // BE middleware: { "error": "..." } — 422 nghiệp vụ, 401, 404...
    if (data['error'] != null) {
      final err = data['error'].toString().trim();
      if (err.isNotEmpty) return err;
    }

    if (data['message'] != null) {
      final msg = data['message'].toString().trim();
      if (msg.isNotEmpty) return msg;
    }

    // ASP.NET validation: { "errors": { "PhoneNumber": ["..."] } }
    if (data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final parts = <String>[];
      for (final entry in errors.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) {
          final field = entry.key.toString();
          final detail = v.first.toString();
          parts.add(field == 'PhoneNumber' || field == 'phoneNumber'
              ? detail
              : '$field: $detail');
        } else if (v != null) {
          parts.add('${entry.key}: $v');
        }
      }
      if (parts.isNotEmpty) return parts.join('\n');
    }

    if (data['title'] != null) {
      return data['title'].toString();
    }

    return '';
  }
}
