import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../services/auth_service.dart';
import 'ngrok_headers.dart';

class DioClient {
  late final Dio _dio;
  final AuthService _authService;
  Future<void> Function()? onUnauthorized;
  Future<String?>? _refreshFuture;

  DioClient(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: ngrokRequestHeaders(),
      ),
    );

    // Logger
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
    ));
    
    // Auth Interceptor: Tự động đính kèm Token vào Header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        applyNgrokBypass(options);
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Nếu nhận lỗi 401 (Unauthorized) và không được yêu cầu bỏ qua logout tự động
        if (e.response?.statusCode == 401 &&
            e.requestOptions.extra['skipAuthLogout'] != true) {
          
          final refreshToken = await _authService.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Sử dụng Future dùng chung để tránh gọi nhiều request refresh đồng thời
              _refreshFuture ??= _performTokenRefresh(refreshToken);
              final newAccessToken = await _refreshFuture;
              
              if (newAccessToken != null) {
                // Thử lại request cũ với Access Token mới
                final requestOptions = e.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                
                // Thực hiện lại request
                final opts = Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                  extra: requestOptions.extra,
                  responseType: requestOptions.responseType,
                  contentType: requestOptions.contentType,
                );
                
                final response = await _dio.request(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: opts,
                );
                
                return handler.resolve(response);
              }
            } catch (err) {
              debugPrint('Lỗi khi retry request sau refresh token: $err');
            } finally {
              // Reset future sau khi hoàn thành
              _refreshFuture = null;
            }
          }
          
          // Nếu không có refreshToken hoặc refresh thất bại -> Tiến hành logout
          final hadAuth = e.requestOptions.headers['Authorization'] != null;
          if (hadAuth) {
            await _authService.deleteToken();
            await _authService.deleteRefreshToken();
            await _authService.clearUserProfile();
            await onUnauthorized?.call();
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<String?> _performTokenRefresh(String refreshToken) async {
    try {
      final tempDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: ngrokRequestHeaders(),
        ),
      );
      tempDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          applyNgrokBypass(options);
          handler.next(options);
        },
      ));

      final response = await tempDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;
        
        if (newAccessToken != null) {
          await _authService.saveToken(newAccessToken);
          if (newRefreshToken != null) {
            await _authService.saveRefreshToken(newRefreshToken);
          }
          return newAccessToken;
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi API refresh token: $e');
    }
    return null;
  }

  Dio get dio => _dio;
}
