import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_endpoints.dart';
import '../network/dio_client.dart';
import 'app_config.dart';

class AppConfigRepository {
  AppConfigRepository(this._dioClient);

  final DioClient _dioClient;

  static const _cacheKey = 'app_config_cache_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Dio get _dio => _dioClient.dio;

  Future<AppConfig> loadConfig() async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiEndpoints.appConfig, options: Options(extra: {'skipAuthLogout': true}));
      final raw = response.data?['config'];
      if (raw is Map<String, dynamic>) {
        final config = AppConfig.fromJson(raw);
        await _saveCache(config);
        return config;
      }
    } catch (e) {
      debugPrint('AppConfigRepository.loadConfig remote failed: $e');
    }

    final cached = await _loadCache();
    return cached ?? defaultAppConfig;
  }

  Future<void> _saveCache(AppConfig config) async {
    try {
      await _storage.write(key: _cacheKey, value: jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint('AppConfigRepository._saveCache: $e');
    }
  }

  Future<AppConfig?> _loadCache() async {
    try {
      final raw = await _storage.read(key: _cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return AppConfig.fromJson(parsed);
      }
    } catch (e) {
      debugPrint('AppConfigRepository._loadCache: $e');
    }
    return null;
  }
}

