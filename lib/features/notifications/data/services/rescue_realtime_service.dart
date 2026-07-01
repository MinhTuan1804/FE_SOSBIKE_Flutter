import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:fe_moblie_flutter/core/network/signalr_hub_url.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';

class RescueRealtimeService {
  final AuthService _authService;
  HubConnection? _connection;
  String? _lastJoinedOrderId;

  final _requestController = StreamController<Map<String, dynamic>>.broadcast();
  final _acceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _accountStatusController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get incomingRescueRequests => _requestController.stream;
  Stream<Map<String, dynamic>> get orderAcceptedUpdates => _acceptedController.stream;
  Stream<String> get orderStatusUpdates => _statusController.stream;
  Stream<String> get accountStatusUpdates => _accountStatusController.stream;

  RescueRealtimeService(this._authService);

  Future<void> connect() async {
    if (_connection != null && _connection!.state == HubConnectionState.Connected) {
      return;
    }

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[RescueRealtime] Bỏ qua connect: chưa có JWT');
      return;
    }

    await _connection?.stop();
    _connection = null;

    final hubUrl = buildSignalRHubUrl('/hubs/rescue');
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

    _connection!.onreconnected(({connectionId}) async {
      debugPrint('Rescue SignalR reconnected with connectionId: $connectionId');
      if (_lastJoinedOrderId != null) {
        try {
          await _connection!.invoke('JoinOrderGroup', args: [_lastJoinedOrderId!]);
          debugPrint('Successfully auto-rejoined rescue order group: $_lastJoinedOrderId');
        } catch (e) {
          debugPrint('Failed to auto-rejoin rescue order group: $e');
        }
      }
    });

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

    _connection!.on('AccountStatusChanged', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is String) {
        _accountStatusController.add(raw);
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
    _lastJoinedOrderId = orderId;
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
}
