import 'dart:convert';

/// Kiểm tra hết hạn JWT từ claim `exp` (giây UTC).
bool isJwtExpired(String token, {Duration clockSkew = const Duration(seconds: 30)}) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
        as Map<String, dynamic>;
    final exp = payload['exp'];
    if (exp is! num) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    return DateTime.now().toUtc().add(clockSkew).isAfter(expiry);
  } catch (_) {
    return true;
  }
}
