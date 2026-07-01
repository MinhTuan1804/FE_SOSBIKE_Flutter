import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';

/// Hub URL kèm `access_token` trên query — cần cho WebSocket native (Android/iOS)
/// vì handshake WS qua nginx đôi khi không chuyển header Authorization.
String buildSignalRHubUrl(String hubPath, String token) {
  var base = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  final encoded = Uri.encodeComponent(token);
  return '$base$hubPath?access_token=$encoded';
}
