import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';

/// Base hub URL (không gắn token ở đây).
/// Token do `accessTokenFactory` của signalr_netcore gắn vào query — tránh trùng
/// `access_token` (ASP.NET gộp thành "tok1,tok2" → JWT invalid → 401 WebSocket).
String buildSignalRHubUrl(String hubPath) {
  final base = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return '$base$hubPath';
}
