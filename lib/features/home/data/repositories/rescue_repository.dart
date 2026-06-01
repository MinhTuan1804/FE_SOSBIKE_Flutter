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
}
