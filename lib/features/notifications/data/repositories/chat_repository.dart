import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/chat_models.dart';

class ChatRepository {
  const ChatRepository(this._dioClient);

  final DioClient _dioClient;

  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.chatConversations);
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => ChatConversation.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ChatMessage>> getMessages(String orderId) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.chatMessages(orderId));
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ChatMessage> sendMessage(String orderId, String content) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.chatMessages(orderId),
        data: {'content': content},
      );
      if (response.data is! Map) {
        throw const FormatException('Phản hồi cuộc hội thoại không hợp lệ.');
      }
      return ChatMessage.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markRead(String orderId) async {
    try {
      await _dioClient.dio.post(ApiEndpoints.chatMarkRead(orderId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
