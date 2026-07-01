import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/signalr_hub_url.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/core/utils/jwt_utils.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/chat_models.dart';

class ChatRealtimeService {
  ChatRealtimeService(this._authService);

  final AuthService _authService;
  HubConnection? _connection;

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messages => _messageController.stream;

  Future<String?> getCurrentUserId() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) return null;
    return getJwtUserId(token);
  }

  Future<void> connect() async {
    if (_connection != null && _connection!.state == HubConnectionState.Connected) {
      return;
    }

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[ChatRealtime] Bỏ qua connect: chưa có JWT');
      return;
    }

    await _connection?.stop();
    _connection = null;

    final hubUrl = buildSignalRHubUrl('/hubs/chat', token);
    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => await _authService.getToken() ?? '',
            requestTimeout: 30000,
          ),
        )
        .withAutomaticReconnect()
        .build();
    _connection!.serverTimeoutInMilliseconds = 120000;
    _connection!.keepAliveIntervalInMilliseconds = 15000;

    _connection!.on('MessageReceived', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        _messageController.add(ChatMessage.fromJson(data));
      }
    });

    await _connection!.start();
  }

  Future<void> joinOrder(String orderId) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      await connect();
    }
    await _connection!.invoke('JoinOrderGroup', args: [orderId]);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }
}
