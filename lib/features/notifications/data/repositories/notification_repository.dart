import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/notification_models.dart';

class NotificationRepository {
  const NotificationRepository(this._dioClient);

  final DioClient _dioClient;

  Future<List<NotificationItem>> getNotifications({bool unreadOnly = false}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'unreadOnly': unreadOnly,
          'page': 1,
          'pageSize': 100,
        },
      );

      final data = response.data;
      final items = data is Map ? data['items'] : null;
      if (items is! List) return [];

      return items
          .whereType<Map>()
          .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.notificationUnreadCount);
      final data = response.data;
      if (data is Map) {
        final value = data['unreadCount'];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markRead(int notificationId) async {
    try {
      await _dioClient.dio.put(ApiEndpoints.notificationMarkRead(notificationId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dioClient.dio.put(ApiEndpoints.notificationMarkAllRead);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
