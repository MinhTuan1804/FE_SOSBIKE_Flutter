import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _keyToken = 'jwt_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _memoryToken;

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: _keyToken, value: token);
    } catch (e) {
      debugPrint('AuthService.saveToken fallback memory: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final stored = await _storage.read(key: _keyToken);
      if (stored != null) {
        _memoryToken = stored;
        return stored;
      }
    } catch (e) {
      debugPrint('AuthService.getToken fallback memory: $e');
    }
    return _memoryToken;
  }

  Future<void> deleteToken() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: _keyToken);
    } catch (e) {
      debugPrint('AuthService.deleteToken: $e');
    }
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
