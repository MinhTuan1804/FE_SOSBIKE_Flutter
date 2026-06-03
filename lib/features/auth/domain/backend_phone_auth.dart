import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:flutter/foundation.dart';

/// Dev/local: đăng nhập & đăng ký qua BE (mật khẩu / OTP BE), không Firebase SMS.
bool get useBackendPhoneAuth {
  if (kIsWeb) return true;
  const force = bool.fromEnvironment('USE_BACKEND_AUTH', defaultValue: false);
  if (force) return true;

  final base = ApiEndpoints.baseUrl.toLowerCase();
  if (base.contains('localhost') ||
      base.contains('127.0.0.1') ||
      base.contains(':5200')) {
    return true;
  }
  final uri = Uri.tryParse(base);
  if (uri == null) return false;
  final host = uri.host;
  if (host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      host.startsWith('172.')) {
    return true;
  }
  return false;
}
