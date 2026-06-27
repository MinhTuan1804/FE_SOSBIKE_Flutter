import 'dart:async';
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
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
            requestTimeout: 30000,
          ),
        )
        .withAutomaticReconnect()
        .build();
    _connection!.serverTimeoutInMilliseconds = 120000;
    _connection!.keepAliveIntervalInMilliseconds = 15000;

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

    await _connection!.start();
  }

  Future<void> joinOrderGroup(String orderId) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      await connect();
    }
    await _connection!.invoke('JoinOrderGroup', args: [orderId]);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      await connect();
    }
    await _connection!.invoke('UpdateOrderStatus', args: [orderId, status]);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  String _buildHubUrl() {
    return ApiEndpoints.hubUrl('rescue');
  }
}
