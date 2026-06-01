import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fe_moblie_flutter/features/home/data/repositories/rescue_repository.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/rescue_realtime_service.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/location_realtime_service.dart';
import 'package:fe_moblie_flutter/core/services/goong_service.dart';

class RescueProvider extends ChangeNotifier {
  final RescueRepository _repository;
  final RescueRealtimeService _realtimeService;
  final LocationRealtimeService _locationService;

  // Goong Route State
  List<LatLng> _activeRoutePoints = [];
  double? _goongDistanceKm;
  int? _goongDurationMins;

  List<LatLng> get activeRoutePoints => _activeRoutePoints;
  double? get goongDistanceKm => _goongDistanceKm;
  int? get goongDurationMins => _goongDurationMins;

  final GoongService _goongService = GoongService();
  DateTime? _lastGoongRouteFetchTime;

  // Active Mechanic Order Coords for dynamic routing on mechanic side
  double? _activeCustomerLatitude;
  double? _activeCustomerLongitude;

  double? get activeCustomerLatitude => _activeCustomerLatitude;
  double? get activeCustomerLongitude => _activeCustomerLongitude;

  RescueProvider(this._repository, this._realtimeService, this._locationService) {
    _setupSignalRListeners();
  }

  // Common State
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Active Order Status State
  String? _activeOrderStatus;
  String? get activeOrderStatus => _activeOrderStatus;

  Map<String, dynamic>? _activeQuote;
  Map<String, dynamic>? get activeQuote => _activeQuote;

  Map<String, dynamic>? _paymentIntent;
  Map<String, dynamic>? get paymentIntent => _paymentIntent;

  // Customer Matching State
  bool _isSearching = false;
  String? _currentOrderId;
  Map<String, dynamic>? _matchedMechanic;
  double? _customerLatitude;
  double? _customerLongitude;

  bool get isSearching => _isSearching;
  String? get currentOrderId => _currentOrderId;
  Map<String, dynamic>? get matchedMechanic => _matchedMechanic;
  double? get customerLatitude => _customerLatitude;
  double? get customerLongitude => _customerLongitude;

  // Mechanic Matching State
  bool _isOnline = false;
  Map<String, dynamic>? _incomingRequest;
  Timer? _locationTimer;
  double? _mechanicLatitude;
  double? _mechanicLongitude;

  bool get isOnline => _isOnline;
  Map<String, dynamic>? get incomingRequest => _incomingRequest;
  double? get mechanicLatitude => _mechanicLatitude;
  double? get mechanicLongitude => _mechanicLongitude;

  StreamSubscription? _requestSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _locationSub;

  Future<void> fetchGoongRoute({
    required double custLat,
    required double custLng,
    required double mechLat,
    required double mechLng,
    bool force = false,
  }) async {
    // Nếu không force và chưa đủ 2 phút (120s) kể từ lần gọi cuối, dùng ước tính Haversine cục bộ
    if (!force && _lastGoongRouteFetchTime != null) {
      final diff = DateTime.now().difference(_lastGoongRouteFetchTime!);
      if (diff < const Duration(minutes: 2)) {
        final distance = _calculateHaversineDistance(custLat, custLng, mechLat, mechLng);
        _goongDistanceKm = distance * 1.25;
        _goongDurationMins = (_goongDistanceKm! * 3).round().clamp(1, 60);
        notifyListeners();
        return;
      }
    }

    final routeData = await _goongService.getRouteData(
      originLat: mechLat,
      originLng: mechLng,
      destLat: custLat,
      destLng: custLng,
    );

    if (routeData.points.isNotEmpty) {
      _activeRoutePoints = routeData.points;
      _goongDistanceKm = routeData.distanceKm;
      _goongDurationMins = routeData.durationMins;
      _lastGoongRouteFetchTime = DateTime.now();
      notifyListeners();
    }
  }

  void _setupSignalRListeners() {
    _requestSub = _realtimeService.incomingRescueRequests.listen((request) {
      debugPrint('Incoming rescue request received via SignalR: $request');
      _incomingRequest = request;
      notifyListeners();
    });

    _acceptedSub = _realtimeService.orderAcceptedUpdates.listen((mechanic) {
      debugPrint('Order accepted update received via SignalR: $mechanic');
      _matchedMechanic = mechanic;
      _isSearching = false;
      notifyListeners();

      if (mechanic != null) {
        // Customer connects to location tracking hub and subscribes
        if (_currentOrderId != null) {
          _locationService.trackOrder(_currentOrderId!);
        }

        // Fetch Goong route immediately using accepted details
        final double? mLat = mechanic['mechanicLatitude'] != null ? (mechanic['mechanicLatitude'] as num).toDouble() : null;
        final double? mLng = mechanic['mechanicLongitude'] != null ? (mechanic['mechanicLongitude'] as num).toDouble() : null;
        if (mLat != null && mLng != null && _customerLatitude != null && _customerLongitude != null) {
          fetchGoongRoute(
            custLat: _customerLatitude!,
            custLng: _customerLongitude!,
            mechLat: mLat,
            mechLng: mLng,
            force: true, // Lần đầu tiên luôn force để vẽ tuyến đường ban đầu
          );
        }
      }
    });

    _statusSub = _realtimeService.orderStatusUpdates.listen((status) {
      debugPrint('Order status updated via SignalR: $status');
      _activeOrderStatus = status;
      if (_matchedMechanic != null) {
        _matchedMechanic!['status'] = status;
      }
      if (status == 'QUOTING' || status == 'COMPLETED' || status == 'REPAIRING' || status == 'PAID') {
        if (_currentOrderId != null) {
          fetchOrderQuote(_currentOrderId!).catchError((e) {
            debugPrint('Failed to auto-fetch quote: $e');
          });
        }
      }
      notifyListeners();
    });

    _locationSub = _locationService.locationUpdates.listen((coords) {
      debugPrint('Mechanic location updated via SignalR LocationHub: $coords');
      final lat = coords['latitude'];
      final lng = coords['longitude'];
      if (lat != null && lng != null) {
        if (_matchedMechanic != null) {
          _matchedMechanic!['mechanicLatitude'] = lat;
          _matchedMechanic!['mechanicLongitude'] = lng;
          notifyListeners();
        }
        if (_customerLatitude != null && _customerLongitude != null) {
          // Thay vì gọi fetchGoongRoute liên tục gây tốn phí API Direction,
          // chúng ta tính khoảng cách đường bộ ước lượng thông qua đường chim bay chim bay (x1.25)
          final distance = _calculateHaversineDistance(
            _customerLatitude!,
            _customerLongitude!,
            lat,
            lng,
          );
          _goongDistanceKm = distance * 1.25; // Nhân hệ số uốn khúc đường bộ
          _goongDurationMins = (_goongDistanceKm! * 3).round().clamp(1, 60); // Ước tính 3 phút/km
          notifyListeners();
        }
      }
    });
  }

  // --- Customer Actions ---

  Future<bool> createRescueOrder({
    required double latitude,
    required double longitude,
    required String requestAddress,
    String? locationNote,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSearching = false;
    _matchedMechanic = null;
    _customerLatitude = null;
    _customerLongitude = null;
    notifyListeners();

    try {
      final res = await _repository.createRescueOrder(
        latitude: latitude,
        longitude: longitude,
        requestAddress: requestAddress,
        locationNote: locationNote,
      );

      _currentOrderId = res['orderId'] as String?;
      _customerLatitude = latitude;
      _customerLongitude = longitude;
      _isSearching = true;
      _isLoading = false;

      // Connect to rescue SignalR hub to wait for matching updates
      await _realtimeService.connect();
      if (_currentOrderId != null) {
        await _realtimeService.joinOrderGroup(_currentOrderId!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchOrderQuote(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repository.getRescueOrderQuote(orderId);
      _activeQuote = res;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createRescueOrderPayment(String orderId, String method) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repository.createRescueOrderPaymentIntent(
        orderId: orderId,
        method: method,
      );
      _paymentIntent = res;
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> confirmRescueOrderPayment(String paymentId, String gatewayTxId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repository.confirmRescueOrderPayment(
        paymentId: paymentId,
        gatewayTransactionId: gatewayTxId,
      );
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> approveOrderQuote(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.approveRescueOrderQuote(orderId);
      _activeOrderStatus = 'REPAIRING';
      if (_matchedMechanic != null) {
        _matchedMechanic!['status'] = 'REPAIRING';
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelSearch() async {
    if (_currentOrderId != null) {
      try {
        await _realtimeService.updateOrderStatus(_currentOrderId!, 'CANCELLED');
      } catch (e) {
        debugPrint('Error sending cancel status: $e');
      }
    }
    _isSearching = false;
    _currentOrderId = null;
    _matchedMechanic = null;
    _customerLatitude = null;
    _customerLongitude = null;
    _activeQuote = null;
    _paymentIntent = null;
    _lastGoongRouteFetchTime = null; // Reset bộ đệm thời gian tải Goong
    await _realtimeService.disconnect();
    notifyListeners();
  }

  // --- Mechanic Actions ---

  Future<void> toggleOnlineStatus(bool online) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedStatus = await _repository.updateMechanicStatus(online);
      _isOnline = updatedStatus;

      if (_isOnline) {
        // Connect to SignalR hub to receive real-time match requests
        await _realtimeService.connect();
        await _locationService.connect();
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();
        await _realtimeService.disconnect();
        await _locationService.disconnect();
        _incomingRequest = null;
        _currentOrderId = null;
        _activeCustomerLatitude = null;
        _activeCustomerLongitude = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void dismissIncomingRequest() {
    _incomingRequest = null;
    notifyListeners();
  }

  void simulateIncomingRequest(Map<String, dynamic> req) {
    _incomingRequest = req;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> acceptRescueOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Connect to SignalR and join the order group FIRST to avoid race conditions
      // where the customer confirms/cancels before the mechanic is in the group.
      await _realtimeService.connect();
      await _realtimeService.joinOrderGroup(orderId);

      if (_incomingRequest != null) {
        _activeCustomerLatitude = _incomingRequest!['latitude'] != null ? (_incomingRequest!['latitude'] as num).toDouble() : null;
        _activeCustomerLongitude = _incomingRequest!['longitude'] != null ? (_incomingRequest!['longitude'] as num).toDouble() : null;
      }
      final res = await _repository.acceptRescueOrder(orderId);
      _currentOrderId = orderId;
      _incomingRequest = null;
      _isLoading = false;
      _activeOrderStatus = 'ACCEPTED';

      // Tải tuyến đường Goong ban đầu một lần duy nhất khi thợ chấp nhận đơn
      if (_activeCustomerLatitude != null && _activeCustomerLongitude != null && _mechanicLatitude != null && _mechanicLongitude != null) {
        fetchGoongRoute(
          custLat: _activeCustomerLatitude!,
          custLng: _activeCustomerLongitude!,
          mechLat: _mechanicLatitude!,
          mechLng: _mechanicLongitude!,
          force: true, // Force tải tuyến đường ban đầu
        ).catchError((e) {
          debugPrint('Failed to fetch initial Goong route: $e');
        });
      }

      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> confirmOrder(String orderId) async {
    try {
      await _realtimeService.updateOrderStatus(orderId, 'CONFIRMED');
    } catch (e) {
      debugPrint('Error sending confirm status: $e');
    }
  }

  void clearActiveOrderStatus() {
    _activeOrderStatus = null;
    _activeQuote = null;
    _paymentIntent = null;
    notifyListeners();
  }

  void updateMechanicLocation(double latitude, double longitude) {
    if (!_isOnline) return;
    _repository.updateMechanicLocation(latitude, longitude).catchError((e) {
      debugPrint('Failed to update mechanic location: $e');
    });
  }

  Future<void> _syncCurrentLocation() async {
    if (!_isOnline) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mechanicLatitude = 10.762622;
        _mechanicLongitude = 106.660172;
        notifyListeners();
        updateMechanicLocation(10.762622, 106.660172);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mechanicLatitude = 10.762622;
          _mechanicLongitude = 106.660172;
          notifyListeners();
          updateMechanicLocation(10.762622, 106.660172);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mechanicLatitude = 10.762622;
        _mechanicLongitude = 106.660172;
        notifyListeners();
        updateMechanicLocation(10.762622, 106.660172);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _mechanicLatitude = position.latitude;
      _mechanicLongitude = position.longitude;
      notifyListeners();
      updateMechanicLocation(position.latitude, position.longitude);
      
      if (_currentOrderId != null) {
        _locationService.sendLocation(_currentOrderId!, position.latitude, position.longitude);
        if (_activeCustomerLatitude != null && _activeCustomerLongitude != null) {
          // Ước tính khoảng cách/thời gian cục bộ
          final distance = _calculateHaversineDistance(
            _activeCustomerLatitude!,
            _activeCustomerLongitude!,
            position.latitude,
            position.longitude,
          );
          _goongDistanceKm = distance * 1.25;
          _goongDurationMins = (_goongDistanceKm! * 3).round().clamp(1, 60);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Geolocator error, using mock: $e');
      _mechanicLatitude = 10.762622;
      _mechanicLongitude = 106.660172;
      notifyListeners();
      updateMechanicLocation(10.762622, 106.660172);

      if (_currentOrderId != null) {
        _locationService.sendLocation(_currentOrderId!, 10.762622, 106.660172);
        if (_activeCustomerLatitude != null && _activeCustomerLongitude != null) {
          final distance = _calculateHaversineDistance(
            _activeCustomerLatitude!,
            _activeCustomerLongitude!,
            10.762622,
            106.660172,
          );
          _goongDistanceKm = distance * 1.25;
          _goongDurationMins = (_goongDistanceKm! * 3).round().clamp(1, 60);
          notifyListeners();
        }
      }
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    // Update location immediately upon going online
    _syncCurrentLocation();
    // Simulate updating location every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncCurrentLocation();
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _acceptedSub?.cancel();
    _statusSub?.cancel();
    _locationSub?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
          cos(lat1 * p) * cos(lat2 * p) * 
          (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
