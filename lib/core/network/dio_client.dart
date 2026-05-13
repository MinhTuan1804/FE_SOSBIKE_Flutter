import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../services/auth_service.dart';

class DioClient {
  late final Dio _dio;
  final AuthService _authService;

  DioClient(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
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
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Xử lý khi Token hết hạn (401)
        if (e.response?.statusCode == 401) {
          await _authService.deleteToken();
          // Ở đây có thể điều hướng người dùng về trang Login nếu cần
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
