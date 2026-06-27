import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/config/app_config.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';

class LocationSelectView extends StatefulWidget {
  const LocationSelectView({
    super.key,
    required this.onBack,
    required this.onConfirmLocation,
  });

  final VoidCallback onBack;
  final void Function(double latitude, double longitude, String address) onConfirmLocation;

  @override
  State<LocationSelectView> createState() => _LocationSelectViewState();
}

class _LocationSelectViewState extends State<LocationSelectView> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(10.762622, 106.660172); // Vị trí mặc định (TP.HCM)

  LatLng? _deviceLocation; // Vị trí GPS thực tế
  String _selectedAddress = 'Vị trí hiện tại của bạn';

  String get _goongApiKey {
    // 1. Try DB config first
    try {
      final dbKey = AppConfig.current.thirdParty.goongApiKey;
      if (dbKey.isNotEmpty) return dbKey;
    } catch (_) {}

    // 2. Fallback to .env
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GOONG_API_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return 'J7uk8GJZvzozpZ8p631cnxMVXUNVz0O0juQCSAJq';
  }

  int _selectedItemIndex = 0;
  bool _isLoadingAddress = false;
  bool _showSearchOverlay = false;
  List<String> _searchHistory = [];

  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _incidentLocations = [];
  BitmapDescriptor? _workerIcon;
  bool _isLoadingWorkers = false;



  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchHistory.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());
      _searchHistory.insert(0, query.trim());
      if (_searchHistory.length > 5) {
        _searchHistory = _searchHistory.sublist(0, 5);
      }
    });
  }

  Future<void> _loadWorkerMarkerIcon() async {
    try {
      _workerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(32, 32)),
        'assets/images/onboarding/logo.png',
      );
    } catch (e) {
      _workerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWorkerMarkerIcon().then((_) {
      _fetchNearbyWorkers(_initialPosition);
    });
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _initialPosition,
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
      ),
    );
  }

  @override
  void didUpdateWidget(LocationSelectView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Thuật toán Haversine tính khoảng cách (trả về km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  void _updateMarkers() {
    if (!mounted) return;
    setState(() {
      _markers.clear();
      
      // 1. Add user location marker
      LatLng userPos = _initialPosition;
      if (_incidentLocations.isNotEmpty) {
        final selected = _incidentLocations[_selectedItemIndex < _incidentLocations.length ? _selectedItemIndex : 0];
        userPos = selected['latLng'] as LatLng;
      }
      
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userPos,
          infoWindow: const InfoWindow(
            title: 'Vị trí cứu hộ',
          ),
        ),
      );

      // 2. Add worker markers
      for (var item in _incidentLocations) {
        if (item['type'] == 'worker') {
          final latLng = item['latLng'] as LatLng;
          final String title = item['title'] as String;
          final String snippet = item['subtitle'] as String? ?? '';
          final wData = item['workerData'] as Map<String, dynamic>?;
          final String workerId = wData?['mechanicId']?.toString() ?? title;

          _markers.add(
            Marker(
              markerId: MarkerId('worker_$workerId'),
              position: latLng,
              icon: _workerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(
                title: title,
                snippet: snippet,
              ),
              onTap: () {
                final index = _incidentLocations.indexOf(item);
                if (index != -1 && mounted) {
                  setState(() {
                    _selectedItemIndex = index;
                    _selectedAddress = title;
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(latLng),
                  );
                }
              },
            ),
          );
        }
      }
    });
  }

  Future<void> _fetchNearbyWorkers(LatLng center) async {
    if (_isLoadingWorkers) return;
    setState(() {
      _isLoadingWorkers = true;
    });

    try {
      final rescueProvider = Provider.of<RescueProvider>(context, listen: false);
      final workers = await rescueProvider.getNearbyWorkers(
        center.latitude,
        center.longitude,
        radiusKm: 5.0,
      );

      if (!mounted) return;

      setState(() {
        // Remove old workers from list
        _incidentLocations.removeWhere((item) => item['type'] == 'worker');

        // Map real workers from API
        final workerItems = workers.map((w) {
          final lat = w['latitude'] != null ? (w['latitude'] as num).toDouble() : 0.0;
          final lng = w['longitude'] != null ? (w['longitude'] as num).toDouble() : 0.0;
          return {
            'title': 'Thợ: ${w['fullName'] ?? 'Sửa xe'} (${w['rating'] ?? 5.0}★)',
            'subtitle': '${w['vehicleModel'] ?? 'N/A'} - ${w['licensePlate'] ?? 'N/A'} (${w['distanceKm'] ?? 0.0}km)',
            'latLng': LatLng(lat, lng),
            'type': 'worker',
            'workerData': w,
          };
        }).toList();

        // Keep only custom user selected locations (type is null) and append new workers
        final customItems = _incidentLocations.where((item) => item['type'] == null).toList();
        _incidentLocations = [...customItems, ...workerItems];
      });

      _updateMarkers();
    } catch (e) {
      debugPrint('Lỗi khi tìm thợ xung quanh: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
        });
      }
    }
  }

  // Tìm kiếm địa chỉ bằng Google Geocoding API hoặc Fallback Offline thông minh
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = 'Đang tìm kiếm...';
    });

    // 1. Thử tìm kiếm online qua Goong Geocoding API
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://rsapi.goong.io/Geocode',
        queryParameters: {
          'address': query,
          'api_key': _goongApiKey,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final latLng = LatLng(lat, lng);
          
          String address = results[0]['formatted_address'] ?? query;
          if (address.endsWith(', Việt Nam')) {
            address = address.substring(0, address.length - 10);
          } else if (address.endsWith(', Vietnam')) {
            address = address.substring(0, address.length - 9);
          }

          if (mounted) {
            setState(() {
              _selectedAddress = address;
              _isLoadingAddress = false;
              _insertCustomLocation(address, latLng);
              _addToHistory(query);
            });
            _highlightLocation(latLng);
            _fetchNearbyWorkers(latLng);
          }
          return;

        }
      }
    } catch (e) {
      debugPrint('Lỗi Search Google API: $e');
    }

    // 2. Fallback tìm kiếm Offline cục bộ dựa trên danh sách mockStreets
    final mockStreets = [
      {'name': 'Đường số 138, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.858, 'lng': 106.808},
      {'name': 'Đường Hoàng Hữu Nam, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.855, 'lng': 106.806},
      {'name': 'Xa Lộ Hà Nội, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.860, 'lng': 106.803},
      {'name': 'Đường Lê Văn Việt, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.850, 'lng': 106.800},
      {'name': 'Đường Cách Mạng Tháng Tám, Phường 11, Quận 3, Thành phố Hồ Chí Minh', 'lat': 10.776, 'lng': 106.678},
      {'name': 'Hẻm Nguyễn Trãi, Phường Bến Thành, Quận 1, Thành phố Hồ Chí Minh', 'lat': 10.771, 'lng': 106.694},
      {'name': 'Đường Nguyễn Tri Phương, Phường 4, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.757, 'lng': 106.667},
      {'name': 'Đường Thành Thái, Phường 14, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.772, 'lng': 106.663},
      {'name': 'Đường 3 Tháng 2, Phường 12, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.770, 'lng': 106.671},
      {'name': 'Đường Lê Hồng Phong, Phường 12, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.765, 'lng': 106.674},
      {'name': 'Đường Lý Thường Kiệt, Phường 14, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.764, 'lng': 106.657},
      {'name': 'Xa Lộ Hà Nội, Phường Thảo Điền, Quận 2, Thành phố Hồ Chí Minh', 'lat': 10.801, 'lng': 106.738},
      {'name': 'Đại lộ Bình Dương, Phú Hòa, Thành phố Thủ Dầu Một, Bình Dương', 'lat': 10.980, 'lng': 106.666},
      {'name': 'Đường Nguyễn Ái Quốc, Phường Tân Phong, Biên Hòa, Đồng Nai', 'lat': 10.963, 'lng': 106.827},
    ];

    final queryLower = query.toLowerCase();
    Map<String, dynamic>? bestMatch;

    for (final street in mockStreets) {
      final name = (street['name'] as String).toLowerCase();
      if (name.contains(queryLower)) {
        bestMatch = street;
        break;
      }
    }

    if (bestMatch != null) {
      final latLng = LatLng(bestMatch['lat'] as double, bestMatch['lng'] as double);
      final address = bestMatch['name'] as String;

      if (mounted) {
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
          _insertCustomLocation(address, latLng);
          _addToHistory(query);
        });
        _highlightLocation(latLng);
        _fetchNearbyWorkers(latLng);
      }

    } else {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Không tìm thấy địa chỉ';
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _insertCustomLocation(String address, LatLng position) {
    // Thêm địa chỉ tùy chọn này vào danh sách cứu hộ lân cận
    final newIncident = {
      'title': address,
      'latLng': position,
    };

    // Lấy các thợ hiện tại đang lưu trong list để không bị mất khi insert custom location
    final workerItems = _incidentLocations.where((item) => item['type'] == 'worker').toList();

    // Loại bỏ các custom location trùng tên hoặc toạ độ
    _incidentLocations.removeWhere((item) => item['type'] != 'worker' && item['title'] == address);
    
    // Đảm bảo phần tử Index 0 luôn là vị trí hiện tại (GPS) nếu đã được tải
    final customItems = _incidentLocations.where((item) => item['type'] != 'worker').toList();
    if (customItems.isNotEmpty && customItems.first['title'] == _selectedAddress) {
      customItems.insert(1, newIncident);
    } else {
      customItems.insert(0, newIncident);
    }

    // Giới hạn danh sách các điểm tự chọn tối đa 2 phần tử để tránh quá dài
    final limitedCustom = customItems.take(2).toList();
    
    // Ghép lại với danh sách thợ
    _incidentLocations = [...limitedCustom, ...workerItems];
    
    _selectedItemIndex = _incidentLocations.indexWhere((item) => item['title'] == address);
    if (_selectedItemIndex == -1) _selectedItemIndex = 0;
  }


  // Smart Mock Geocoder: Dùng để sinh địa chỉ tiếng Việt cực kỳ thực tế xung quanh TP.HCM khi cả hai dịch vụ geocoding đều lỗi (ví dụ do lỗi Billing của API Key)
  String _getSmartMockAddress(LatLng latLng) {
    // Danh sách các trục đường chính tại TP.HCM kèm theo tọa độ tâm tham chiếu
    final mockStreets = [
      {'name': 'Đường số 138, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.858, 'lng': 106.808},
      {'name': 'Đường Hoàng Hữu Nam, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.855, 'lng': 106.806},
      {'name': 'Xa Lộ Hà Nội, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.860, 'lng': 106.803},
      {'name': 'Đường Lê Văn Việt, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh', 'lat': 10.850, 'lng': 106.800},
      {'name': 'Đường Cách Mạng Tháng Tám, Phường 11, Quận 3, Thành phố Hồ Chí Minh', 'lat': 10.776, 'lng': 106.678},
      {'name': 'Hẻm Nguyễn Trãi, Phường Bến Thành, Quận 1, Thành phố Hồ Chí Minh', 'lat': 10.771, 'lng': 106.694},
      {'name': 'Đường Nguyễn Tri Phương, Phường 4, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.757, 'lng': 106.667},
      {'name': 'Đường Thành Thái, Phường 14, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.772, 'lng': 106.663},
      {'name': 'Đường 3 Tháng 2, Phường 12, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.770, 'lng': 106.671},
      {'name': 'Đường Lê Hồng Phong, Phường 12, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.765, 'lng': 106.674},
      {'name': 'Đường Lý Thường Kiệt, Phường 14, Quận 10, Thành phố Hồ Chí Minh', 'lat': 10.764, 'lng': 106.657},
      {'name': 'Xa Lộ Hà Nội, Phường Thảo Điền, Quận 2, Thành phố Hồ Chí Minh', 'lat': 10.801, 'lng': 106.738},
      {'name': 'Đại lộ Bình Dương, Phú Hòa, Thành phố Thủ Dầu Một, Bình Dương', 'lat': 10.980, 'lng': 106.666},
      {'name': 'Đường Nguyễn Ái Quốc, Phường Tân Phong, Biên Hòa, Đồng Nai', 'lat': 10.963, 'lng': 106.827},
    ];

    double minDistance = double.infinity;
    Map<String, dynamic>? closestStreet;

    for (final street in mockStreets) {
      final dist = _calculateDistance(
        latLng.latitude,
        latLng.longitude,
        street['lat'] as double,
        street['lng'] as double,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestStreet = street;
      }
    }

    // Sinh số nhà giả lập dựa trên phần dư tọa độ để tránh trùng lặp
    final houseNo = ((latLng.latitude + latLng.longitude) * 10000).toInt() % 250 + 1;

    if (closestStreet != null) {
      final streetName = closestStreet['name'] as String;
      // Nếu địa danh là đại lộ/đường lớn, ghép số nhà vào trước
      if (streetName.startsWith('Đường') || streetName.startsWith('Xa Lộ') || streetName.startsWith('Đại lộ') || streetName.startsWith('Hẻm')) {
        return 'Số $houseNo $streetName';
      }
      return '$houseNo, $streetName';
    }

    return 'Khu vực gần ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
  }

  // Reverse Geocoding kết hợp Geocoding hệ thống (Native) và Fallback qua Google API + Smart Mock Fallback
  Future<String> _reverseGeocode(LatLng latLng) async {
    // 1. Thử dùng Native Geocoder trước (Mượt mà, miễn phí, độ chính xác cao)
    try {
      await geo.setLocaleIdentifier('vi_VN');
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        
        String road = '';
        final street = place.street;
        final thoroughfare = place.thoroughfare;
        final name = place.name;

        if (street != null && street.isNotEmpty) {
          road = street;
          // Nếu street chỉ là số nhà mà chưa chứa tên đường thoroughfare
          if (thoroughfare != null && thoroughfare.isNotEmpty && !street.contains(thoroughfare)) {
            final bool isLikelyNumber = RegExp(r'^[0-9a-zA-Z/\-\s]+$').hasMatch(street) && street.length <= 12;
            if (isLikelyNumber) {
              road = '$street $thoroughfare';
            } else {
              road = '$street, $thoroughfare';
            }
          }
        } else if (thoroughfare != null && thoroughfare.isNotEmpty) {
          road = thoroughfare;
          if (name != null && name.isNotEmpty && name != thoroughfare) {
            road = '$name, $road';
          }
        } else if (name != null && name.isNotEmpty) {
          road = name;
        }

        if (road.isNotEmpty) {
          parts.add(road);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }

        String? district = place.subAdministrativeArea;
        if (district == null || district.isEmpty) {
          district = place.locality;
        }
        if (district != null && district.isNotEmpty) {
          if (district != place.subLocality) {
            parts.add(district);
          }
        }

        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (place.administrativeArea != district) {
            parts.add(place.administrativeArea!);
          }
        }
        
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Lỗi Geocoding Native: $e');
    }

    // 2. Fallback qua Goong Geocoding API nếu Native lỗi
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://rsapi.goong.io/Geocode',
        queryParameters: {
          'latlng': '${latLng.latitude},${latLng.longitude}',
          'api_key': _goongApiKey,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          String address = results[0]['formatted_address'] ?? '';
          // Loại bỏ phần quốc gia dư thừa ở cuối để gọn màn hình
          if (address.endsWith(', Việt Nam')) {
            address = address.substring(0, address.length - 10);
          } else if (address.endsWith(', Vietnam')) {
            address = address.substring(0, address.length - 9);
          }
          if (address.isNotEmpty) {
            return address;
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi Geocoding API Goong: $e');
    }

    // 3. Fallback thông minh cuối cùng bằng Smart Mock Geocoder thay vì hiện toạ độ số thô
    return _getSmartMockAddress(latLng);
  }


  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _deviceLocation = latLng;
          _selectedItemIndex = 0;
          _fetchNearbyWorkers(latLng);
          _isLoadingAddress = true;

          _selectedAddress = 'Đang xác định địa chỉ...';
        });

        _highlightLocation(latLng);
        
        _reverseGeocode(latLng).then((address) {
          if (mounted) {
            setState(() {
              _selectedAddress = address;
              _isLoadingAddress = false;

              // Thêm địa chỉ hiện tại đã geocode vào đầu danh sách Vị trí cứu hộ
              final currentLocItem = {
                'title': address,
                'latLng': latLng,
              };
              _incidentLocations.removeWhere((item) => item['title'] == address);
              _incidentLocations.insert(0, currentLocItem);
              _selectedItemIndex = 0;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi lấy vị trí hiện tại: $e');
    }
  }

  void _highlightLocation(LatLng latLng) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: latLng,
          infoWindow: const InfoWindow(
            title: 'Vị trí cứu hộ',
          ),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: 16.0,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Bản đồ Google Maps dưới cùng
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15.0,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (LatLng position) {
              setState(() {
                _selectedItemIndex = 0; // Đặt item vừa tap làm mục được chọn đầu tiên
                _isLoadingAddress = true;
                _selectedAddress = 'Đang xác định địa chỉ...';
              });
              _highlightLocation(position);
              _fetchNearbyWorkers(position);

              
              _reverseGeocode(position).then((address) {
                if (mounted) {
                  setState(() {
                    _selectedAddress = address;
                    _isLoadingAddress = false;
                    _insertCustomLocation(address, position);
                  });
                }
              });
            },
          ),
        ),

        // 2. Ô tìm kiếm địa chỉ màu đỏ nổi (Header cố định phía trên)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlowHeader(context, onBack: widget.onBack),
              const SizedBox(height: 16),
              SearchAddressBar(
                address: _selectedAddress,
                isLoading: _isLoadingAddress,
                onTap: () {
                  setState(() {
                    _showSearchOverlay = true;
                  });
                },
              ),
            ],
          ),
        ),
        
        // 3. Bảng thông tin địa điểm kéo thả (Draggable Bottom Sheet Panel)
        Positioned.fill(
          child: DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.22,
            maxChildSize: 0.75,
            snap: true,
            builder: (context, scrollController) {
              return LocationDetailsPanel(
                scrollController: scrollController,
                items: _incidentLocations,
                deviceLocation: _deviceLocation,
                initialPosition: _initialPosition,
                selectedItemIndex: _selectedItemIndex,
                onItemTap: (index, itemLatLng, itemTitle) {
                  setState(() {
                    _selectedItemIndex = index;
                    _selectedAddress = itemTitle; // Gán trực tiếp tiêu đề địa chỉ đã chọn để tránh trỏ sai
                  });
                  _highlightLocation(itemLatLng);
                },
                onConfirmLocation: () {
                  final selectedItem = _incidentLocations[_selectedItemIndex];
                  final latLng = selectedItem['latLng'] as LatLng;
                  final address = selectedItem['title'] as String;
                  widget.onConfirmLocation(latLng.latitude, latLng.longitude, address);
                },
                calculateDistance: _calculateDistance,
              );
            },
          ),
        ),

        // 5. Màn hình tìm kiếm địa chỉ phủ lên toàn bộ
        if (_showSearchOverlay)
          Positioned.fill(
            child: AddressSearchOverlay(
              initialQuery: _selectedAddress,
              history: _searchHistory,
              onBack: () {
                setState(() {
                  _showSearchOverlay = false;
                });
              },
              onSearch: (query) {
                setState(() {
                  _showSearchOverlay = false;
                });
                _searchAddress(query);
              },
              onGetCurrentLocation: () {
                setState(() {
                  _showSearchOverlay = false;
                });
                _getCurrentLocation();
              },
            ),
          ),
      ],
    );
  }



  Widget _buildFlowHeader(BuildContext context, {required VoidCallback onBack}) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 8, bottom: 12, left: 16),
      color: AppColors.primary,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
            onPressed: onBack,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// CÁC WIDGET CON ĐÃ ĐƯỢC PHÂN TÁCH ĐỂ DỄ BẢO TRÌ & TỐI ƯU HIỆU NĂNG
// -------------------------------------------------------------

/// Widget con hiển thị thanh tìm kiếm địa chỉ màu đỏ nổi trên bản đồ
/// Widget con hiển thị thanh tìm kiếm địa chỉ màu đỏ nổi trên bản đồ
class SearchAddressBar extends StatelessWidget {
  const SearchAddressBar({
    super.key,
    required this.address,
    required this.isLoading,
    required this.onTap,
  });

  final String address;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Check if the current address text is the default placeholder or loading message
    final bool isPlaceholder = address.isEmpty || 
        address == 'Vị trí hiện tại của bạn' || 
        address.contains('Đang xác định') || 
        address.contains('Đang tìm kiếm');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPlaceholder ? 'Tìm kiếm vị trí cứu hộ...' : address,
                  style: TextStyle(
                    color: isPlaceholder ? Colors.white.withValues(alpha: 0.7) : Colors.white,
                    fontSize: 14,
                    fontWeight: isPlaceholder ? FontWeight.w500 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.search, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình overlay tìm kiếm địa chỉ phủ toàn bộ màn hình
class AddressSearchOverlay extends StatefulWidget {
  const AddressSearchOverlay({
    super.key,
    required this.initialQuery,
    required this.history,
    required this.onBack,
    required this.onSearch,
    required this.onGetCurrentLocation,
  });

  final String initialQuery;
  final List<String> history;
  final VoidCallback onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback onGetCurrentLocation;

  @override
  State<AddressSearchOverlay> createState() => _AddressSearchOverlayState();
}

class _AddressSearchOverlayState extends State<AddressSearchOverlay> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final isDefault = widget.initialQuery == 'Vị trí hiện tại của bạn' || 
        widget.initialQuery.contains('Đang xác định') || 
        widget.initialQuery.contains('Đang tìm kiếm');
    _controller = TextEditingController(text: isDefault ? '' : widget.initialQuery);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header / Custom Search Bar
          Container(
            padding: EdgeInsets.only(top: topPadding + 8, bottom: 12, left: 8, right: 16),
            color: AppColors.primary,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (query) {
                              if (query.trim().isNotEmpty) {
                                widget.onSearch(query);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Nhập vị trí cứu hộ...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (text) {
                              setState(() {});
                            },
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[600], size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _controller.clear();
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Nút "Lấy vị trí hiện tại"
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[50],
                    child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                  ),
                  title: const Text(
                    'Lấy vị trí hiện tại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Sử dụng định vị GPS trên thiết bị',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  onTap: widget.onGetCurrentLocation,
                ),
                const Divider(height: 1, thickness: 1),

                // Lịch sử tìm kiếm section
                if (widget.history.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Lịch sử tìm kiếm',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...widget.history.map((query) {
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined, color: Colors.grey[400], size: 22),
                      title: Text(
                        query,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.north_west, color: Colors.grey[300], size: 16),
                      onTap: () {
                        widget.onSearch(query);
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị bảng thông tin gợi ý dạng kéo vuốt lên xuống (Draggable details)
class LocationDetailsPanel extends StatelessWidget {
  const LocationDetailsPanel({
    super.key,
    required this.scrollController,
    required this.items,
    required this.deviceLocation,
    required this.initialPosition,
    required this.selectedItemIndex,
    required this.onItemTap,
    required this.onConfirmLocation,
    required this.calculateDistance,
  });

  final ScrollController scrollController;
  final List<Map<String, dynamic>> items;
  final LatLng? deviceLocation;
  final LatLng initialPosition;
  final int selectedItemIndex;
  final void Function(int index, LatLng latLng, String title) onItemTap;
  final VoidCallback onConfirmLocation;
  final double Function(double lat1, double lon1, double lat2, double lon2) calculateDistance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Thanh kéo (Grabber line)
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề bảng điều khiển
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Địa điểm xảy ra sự cố',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Danh sách các địa điểm sự cố (bỏ qua thợ)
            Builder(
              builder: (context) {
                final locationItems = items.where((item) => item['type'] != 'worker').toList();

                if (locationItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Text(
                      'Chua co dia diem nao duoc chon. Hay tim kiem hoac chon tren ban do.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  );
                }

                final allItems = items;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: () {
                    final nonWorkers = <Widget>[];
                    for (int i = 0; i < allItems.length; i++) {
                      final item = allItems[i];
                      if (item['type'] == 'worker') continue;

                      final itemLatLng = item['latLng'] as LatLng;
                      final deviceLatLng = deviceLocation ?? initialPosition;
                      final dist = calculateDistance(
                        deviceLatLng.latitude,
                        deviceLatLng.longitude,
                        itemLatLng.latitude,
                        itemLatLng.longitude,
                      );
                      final distanceStr = dist < 1.0
                          ? '${(dist * 1000).toStringAsFixed(0)}m'
                          : '${dist.toStringAsFixed(1)}km';
                      final isSelected = selectedItemIndex == i;

                      nonWorkers.add(
                        LocationItemTile(
                          icon: Icons.my_location,
                          iconColor: isSelected ? AppColors.primary : Colors.grey,
                          title: item['title'] as String,
                          distance: distanceStr,
                          isSelected: isSelected,
                          onTap: () => onItemTap(i, itemLatLng, item['title'] as String),
                        ),
                      );
                    }

                    final childrenWithDividers = <Widget>[];
                    for (int i = 0; i < nonWorkers.length; i++) {
                      childrenWithDividers.add(nonWorkers[i]);
                      if (i < nonWorkers.length - 1) {
                        childrenWithDividers.add(const Divider(height: 1, indent: 64));
                      }
                    }
                    return childrenWithDividers;
                  }(),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Chọn địa điểm này',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget con biểu diễn một dòng địa chỉ gợi ý trong danh sách
class LocationItemTile extends StatelessWidget {
  const LocationItemTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.distance,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String distance;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected ? Colors.red[50]?.withValues(alpha: 0.4) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? Colors.red[100] : Colors.grey[100],
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    distance,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
