import 'dart:async';

import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/core/utils/jwt_utils.dart';
import 'package:fe_moblie_flutter/features/notifications/data/models/notification_models.dart';
import 'package:signalr_netcore/signalr_client.dart';

class NotificationRealtimeService {
  NotificationRealtimeService(this._authService);

  final AuthService _authService;
  HubConnection? _connection;

  final StreamController<NotificationItem> _notificationController =
      StreamController<NotificationItem>.broadcast();

  Stream<NotificationItem> get notifications => _notificationController.stream;

  Future<String?> getCurrentUserId() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) return null;
    return getJwtUserId(token);
  }

  Future<void> connect() async {
    if (_connection != null && _connection!.state == HubConnectionState.Connected) {
      return;
    }

    final hubUrl = _buildHubUrl();
    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => await _authService.getToken() ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('NotificationCreated', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is Map) {
        _notificationController.add(NotificationItem.fromJson(Map<String, dynamic>.from(raw)));
      }
    });

    await _connection!.start();
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  String _buildHubUrl() {
    var base = ApiEndpoints.baseUrl;
    base = base.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/hubs/notifications';
  }
}
