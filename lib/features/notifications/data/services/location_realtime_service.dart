import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';


class LocationRealtimeService {
  final AuthService _authService;
  HubConnection? _connection;

  final _locationController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get locationUpdates => _locationController.stream;

  LocationRealtimeService(this._authService);

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

    _connection!.on('LocationUpdated', (arguments) {
      if (arguments == null || arguments.length < 2) return;
      final double lat = (arguments[0] as num).toDouble();
      final double lng = (arguments[1] as num).toDouble();
      _locationController.add({'latitude': lat, 'longitude': lng});
    });

    await _connection!.start();
  }

  Future<void> trackOrder(String orderId) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      await connect();
    }
    await _connection!.invoke('TrackOrder', args: [orderId]);
  }

  Future<void> sendLocation(String orderId, double lat, double lng) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      await connect();
    }
    await _connection!.invoke('SendLocation', args: [orderId, lat, lng]);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  String _buildHubUrl() {
    return ApiEndpoints.hubUrl('location');
  }
}
