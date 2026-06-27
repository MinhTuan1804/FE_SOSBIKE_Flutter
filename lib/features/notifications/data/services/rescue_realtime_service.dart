import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';

class RescueRealtimeService {
  final AuthService _authService;
  HubConnection? _connection;

  final _requestController = StreamController<Map<String, dynamic>>.broadcast();
  final _acceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get incomingRescueRequests => _requestController.stream;
  Stream<Map<String, dynamic>> get orderAcceptedUpdates => _acceptedController.stream;
  Stream<String> get orderStatusUpdates => _statusController.stream;

  RescueRealtimeService(this._authService);

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
            transport: HttpTransportType.LongPolling,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('IncomingRescueRequest', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is Map) {
        _requestController.add(Map<String, dynamic>.from(raw));
      }
    });

    _connection!.on('OrderAccepted', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is Map) {
        _acceptedController.add(Map<String, dynamic>.from(raw));
      }
    });

    _connection!.on('OrderStatusUpdated', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is String) {
        _statusController.add(raw);
      }
    });

    try {
      await _connection!.start();
    } catch (error) {
      debugPrint('RescueRealtimeService.connect failed: $error');
      try {
        await _connection?.stop();
      } catch (_) {}
      _connection = null;
      rethrow;
    }
  }

  Future<void> joinOrderGroup(String orderId) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      try {
        await connect();
      } catch (error) {
        debugPrint('RescueRealtimeService.joinOrderGroup connect failed: $error');
        return;
      }
    }
    try {
      await _connection!.invoke('JoinOrderGroup', args: [orderId]);
    } catch (error) {
      debugPrint('RescueRealtimeService.joinOrderGroup failed: $error');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      try {
        await connect();
      } catch (error) {
        debugPrint('RescueRealtimeService.updateOrderStatus connect failed: $error');
        return;
      }
    }
    try {
      await _connection!.invoke('UpdateOrderStatus', args: [orderId, status]);
    } catch (error) {
      debugPrint('RescueRealtimeService.updateOrderStatus failed: $error');
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  String _buildHubUrl() {
    var base = ApiEndpoints.baseUrl;
    base = base.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/hubs/rescue';
  }
}

