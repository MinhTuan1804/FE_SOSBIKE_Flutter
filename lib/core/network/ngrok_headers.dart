import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';

/// Ngrok free: Web gọi XHR từ localhost → cần bypass trang cảnh báo (không thì lỗi CORS).
bool get isNgrokApiBaseUrl {
  final base = ApiEndpoints.baseUrl.toLowerCase();
  return base.contains('ngrok-free.app') ||
      base.contains('ngrok-free.dev') ||
      base.contains('ngrok.io');
}

Map<String, String> ngrokRequestHeaders() {
  if (!isNgrokApiBaseUrl) return {};
  return const {'ngrok-skip-browser-warning': 'true'};
}

/// Gắn header + query (Web) trước mỗi request tới ngrok.
void applyNgrokBypass(RequestOptions options) {
  if (!isNgrokApiBaseUrl) return;

  for (final e in ngrokRequestHeaders().entries) {
    options.headers[e.key] = e.value;
  }

  // Flutter Web: thêm query để tránh một số trường hợp preflight/CORS với custom header.
  if (kIsWeb) {
    options.queryParameters.putIfAbsent(
      'ngrok-skip-browser-warning',
      () => 'true',
    );
  }
}
