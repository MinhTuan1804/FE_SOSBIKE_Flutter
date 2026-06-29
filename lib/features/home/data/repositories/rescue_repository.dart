import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';

class RescueRepository {
  final DioClient _dioClient;

  RescueRepository(this._dioClient);

  Future<Map<String, dynamic>> createRescueOrder({
    required double latitude,
    required double longitude,
    required String requestAddress,
    String? locationNote,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/RescueOrders',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'requestAddress': requestAddress,
          if (locationNote != null) 'locationNote': locationNote,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> acceptRescueOrder(String orderId) async {
    try {
      final response = await _dioClient.dio.post(
        '/RescueOrders/$orderId/accept',
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Thợ chủ động lấy danh sách đơn cứu hộ PENDING gần vị trí hiện tại.
  Future<List<Map<String, dynamic>>> getAvailableRescueOrders() async {
    try {
      final response = await _dioClient.dio.get('/RescueOrders/available');
      final data = response.data;
      final list = (data is Map ? data['orders'] : null) as List? ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<bool> updateMechanicStatus(bool isOnline) async {
    try {
      final response = await _dioClient.dio.put(
        '/RescueOrders/mechanic/status',
        queryParameters: {'isOnline': isOnline},
      );
      final status = response.data['status'] as String?;
      return status == 'ONLINE';
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateMechanicLocation(double latitude, double longitude) async {
    try {
      await _dioClient.dio.put(
        '/RescueOrders/mechanic/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getRescueOrderQuote(String orderId) async {
    try {
      final response = await _dioClient.dio.get('/RescueOrders/$orderId/quote');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> createRescueOrderPaymentIntent({
    required String orderId,
    required String method,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/payments/intents',
        data: {
          'purpose': 'RESCUE_ORDER',
          'orderId': orderId,
          'method': method,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> confirmRescueOrderPayment({
    required String paymentId,
    required String gatewayTransactionId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/payments/$paymentId/confirm',
        data: {
          'gatewayTransactionId': gatewayTransactionId,
          'autoRenew': false,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> approveRescueOrderQuote(String orderId) async {
    try {
      final response = await _dioClient.dio.post(
        '/RescueOrders/$orderId/approve-quote',
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyWorkers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 10,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/workers/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'limit': limit,
        },
      );
      return List<Map<String, dynamic>>.from(
        (response.data as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>?> getActiveOrderForCustomer() async {
    try {
      final response = await _dioClient.dio.get('/RescueOrders/me/active');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }
}
