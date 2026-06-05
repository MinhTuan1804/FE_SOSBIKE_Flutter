import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fe_moblie_flutter/core/utils/jwt_utils.dart';

class AuthService {
  static const _keyToken = 'jwt_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserName = 'user_full_name';
  static const _keyAvatarUrl = 'user_avatar_url';
  static const _keyBlogVisitorId = 'blog_visitor_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  String? _memoryToken;
  String? _memoryBlogVisitorId;

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: _keyToken, value: token);
    } catch (e) {
      debugPrint('AuthService.saveToken fallback memory: $e');
    }
  }

  Future<String?> getToken() async {
    if (_memoryToken != null && _memoryToken!.isNotEmpty) {
      return _memoryToken;
    }
    try {
      final stored = await _storage
          .read(key: _keyToken)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (stored != null && stored.isNotEmpty) {
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

  Future<void> saveAvatarUrl(String? url) async {
    try {
      if (url == null || url.isEmpty) {
        await _storage.delete(key: _keyAvatarUrl);
      } else {
        await _storage.write(key: _keyAvatarUrl, value: url);
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

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
    } catch (e) {
      debugPrint('AuthService.saveRefreshToken: $e');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('AuthService.getRefreshToken: $e');
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('AuthService.deleteRefreshToken: $e');
    }
  }

  Future<void> clearUserProfile() async {
    try {
      await _storage.delete(key: _keyUserName);
      await _storage.delete(key: 'user_type');
      await _storage.delete(key: _keyAvatarUrl);
      await _storage.delete(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('AuthService.clearUserProfile: $e');
    }
  }

  Future<String> getOrCreateBlogVisitorId() async {
    if (_memoryBlogVisitorId != null && _memoryBlogVisitorId!.isNotEmpty) {
      return _memoryBlogVisitorId!;
    }

    try {
      final stored = await _storage.read(key: _keyBlogVisitorId);
      if (stored != null && stored.isNotEmpty) {
        _memoryBlogVisitorId = stored;
        return stored;
      }

      final visitorId = _generateVisitorId();
      _memoryBlogVisitorId = visitorId;
      await _storage.write(key: _keyBlogVisitorId, value: visitorId);
      return visitorId;
    } catch (e) {
      debugPrint('AuthService.getOrCreateBlogVisitorId fallback memory: $e');
      final visitorId = _memoryBlogVisitorId ?? _generateVisitorId();
      _memoryBlogVisitorId = visitorId;
      return visitorId;
    }
  }

  String _generateVisitorId() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
