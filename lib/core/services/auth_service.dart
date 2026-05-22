import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fe_moblie_flutter/core/utils/jwt_utils.dart';

class AuthService {
  static const _keyToken = 'jwt_token';
  static const _keyUserName = 'user_full_name';
  static const _keyAvatarUrl = 'user_avatar_url';

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
      final stored = await _storage
          .read(key: _keyToken)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
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

  /// Token còn hạn; token hết hạn hoặc lỗi parse sẽ bị xóa khỏi storage.
  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    if (!isJwtExpired(token)) return true;

    await deleteToken();
    await clearUserProfile();
    return false;
  }

  Future<void> saveUserName(String fullName) async {
    try {
      await _storage.write(key: _keyUserName, value: fullName);
    } catch (e) {
      debugPrint('AuthService.saveUserName: $e');
    }
  }

  Future<String?> getUserName() async {
    try {
      return await _storage.read(key: _keyUserName);
    } catch (e) {
      debugPrint('AuthService.getUserName: $e');
      return null;
    }
  }

  Future<void> saveUserType(String userType) async {
    try {
      await _storage.write(key: 'user_type', value: userType);
    } catch (e) {
      debugPrint('AuthService.saveUserType: $e');
    }
  }

  Future<String?> getUserType() async {
    try {
      return await _storage.read(key: 'user_type');
    } catch (e) {
      debugPrint('AuthService.getUserType: $e');
      return null;
    }
  }

  Future<void> saveAvatarUrl(String? avatarUrl) async {
    try {
      if (avatarUrl == null || avatarUrl.isEmpty) {
        await _storage.delete(key: _keyAvatarUrl);
      } else {
        await _storage.write(key: _keyAvatarUrl, value: avatarUrl);
      }
    } catch (e) {
      debugPrint('AuthService.saveAvatarUrl: $e');
    }
  }

  Future<String?> getAvatarUrl() async {
    try {
      return await _storage.read(key: _keyAvatarUrl);
    } catch (e) {
      debugPrint('AuthService.getAvatarUrl: $e');
      return null;
    }
  }

  Future<void> clearUserProfile() async {
    try {
      await _storage.delete(key: _keyUserName);
      await _storage.delete(key: 'user_type');
      await _storage.delete(key: _keyAvatarUrl);
    } catch (e) {
      debugPrint('AuthService.clearUserProfile: $e');
    }
  }
}
