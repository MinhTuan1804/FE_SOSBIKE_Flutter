import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

class LocationSelectView extends StatefulWidget {
  const LocationSelectView({
    key,
    required this.onBack,
    required this.onConfirmLocation,
  }) : super(key: key);

  final VoidCallback onBack;
  final VoidCallback onAddNote;
  final void Function(double latitude, double longitude, String address) onConfirmLocation;
  final ValueChanged<String>? onNoteChanged;

  @override
  State<LocationSelectView> createState() => _LocationSelectViewState();
}

class _LocationSelectViewState extends State<LocationSelectView> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(10.762622, 106.660172); // Vị trí mặc định (TP.HCM)

  LatLng? _deviceLocation; // Vị trí GPS thực tế
  String _selectedAddress = 'Vị trí hiện tại của bạn';

  String get _goongApiKey {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['GOONG_API_KEY'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  int _selectedItemIndex = 0;
  bool _isLoadingAddress = false;
  bool _showSearchOverlay = false;
  List<String> _searchHistory = [];

  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _incidentLocations = [];



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

  @override
  void initState() {
    super.initState();
    _updateLocations(_initialPosition);
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
    final c = cos;
    final a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  // Cập nhật danh sách các điểm xung quanh tâm bản đồ
  void _updateLocations(LatLng center) {
    // Tọa độ 4 điểm sự cố lân cận mô phỏng trong bán kính 200m
    final incident1LatLng = LatLng(center.latitude + 0.0008, center.longitude - 0.0006); // ~90m
    final incident2LatLng = LatLng(center.latitude - 0.0012, center.longitude + 0.0010); // ~150m
    final incident3LatLng = LatLng(center.latitude + 0.0005, center.longitude + 0.0013); // ~140m
    final incident4LatLng = LatLng(center.latitude - 0.0014, center.longitude - 0.0008); // ~170m

    final tempIncidents = [
      {
        'title': 'Sự cố hỏng xích - Đang xác định vị trí...',
        'latLng': incident1LatLng,
        'type': 'incident_1',
      },
      {
        'title': 'Bể bánh xe - Đang xác định vị trí...',
        'latLng': incident2LatLng,
        'type': 'incident_2',
      },
      {
        'title': 'Chết máy đột ngột - Đang xác định vị trí...',
        'latLng': incident3LatLng,
        'type': 'incident_3',
      },
      {
        'title': 'Thủng lốp xe - Đang xác định vị trí...',
        'latLng': incident4LatLng,
        'type': 'incident_4',
      },
    ];

    setState(() {
      // Giữ lại các điểm tự chọn (không có trường 'type')
      final customItems = _incidentLocations.where((item) {
        return item['type'] == null;
      }).toList();
      _incidentLocations = [...customItems, ...tempIncidents];
      
      // Giới hạn danh sách tối đa 5 phần tử (1 GPS hiện tại ở đầu + 4 lân cận)
      if (_incidentLocations.length > 5) {
        _incidentLocations = _incidentLocations.sublist(0, 5);
      }
    });

    // Giải mã địa chỉ bất đồng bộ cho từng sự cố để khớp tọa độ với tiêu đề hiển thị
    _reverseGeocode(incident1LatLng).then((address) {
      _updateIncidentTitle('incident_1', 'Sự cố hỏng xích - $address');
    });
    _reverseGeocode(incident2LatLng).then((address) {
      _updateIncidentTitle('incident_2', 'Bể bánh xe - $address');
    });
    _reverseGeocode(incident3LatLng).then((address) {
      _updateIncidentTitle('incident_3', 'Chết máy đột ngột - $address');
    });
    _reverseGeocode(incident4LatLng).then((address) {
      _updateIncidentTitle('incident_4', 'Thủng lốp xe - $address');
    });
  }

  void _updateIncidentTitle(String type, String newTitle) {
    if (!mounted) return;
    setState(() {
      for (var item in _incidentLocations) {
        if (item['type'] == type) {
          item['title'] = newTitle;
        }
      }
    });
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

    // Loại bỏ bất kỳ phần tử nào trùng tiêu đề hoặc trùng tọa độ cũ
    _incidentLocations.removeWhere((item) => item['title'] == address);
    
    // Đảm bảo phần tử Index 0 luôn là vị trí hiện tại (GPS) nếu đã được tải
    if (_incidentLocations.isNotEmpty && _incidentLocations.first['type'] == null && _incidentLocations.first['title'] == _selectedAddress) {
      // Vị trí GPS hiện tại đang ở đầu, chèn vào ngay sau nó (Index 1)
      _incidentLocations.insert(1, newIncident);
    } else {
      // Chèn lên đầu
      _incidentLocations.insert(0, newIncident);
    }

    // Giới hạn danh sách tối đa 5 phần tử: 1 GPS hiện tại + 4 lân cận
    if (_incidentLocations.length > 5) {
      _incidentLocations = _incidentLocations.sublist(0, 5);
    }
    
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
          _updateLocations(latLng);
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
        if (!_showNoteInput)
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
                  mechanicNote: _currentNote,
                  onItemTap: (index, itemLatLng, itemTitle) {
                    setState(() {
                      _selectedItemIndex = index;
                      _selectedAddress = itemTitle; // Gán trực tiếp tiêu đề địa chỉ đã chọn để tránh trỏ sai
                    });
                    _highlightLocation(itemLatLng);
                  },
                  onAddNote: () {
                    setState(() {
                      _showNoteInput = true;
                    });
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
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
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
                        Icon(Icons.search, color: AppColors.primary, size: 20),
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
                    child: Icon(Icons.my_location, color: AppColors.primary, size: 20),
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

            // Tiêu đề bảng điều khiển (Bỏ hoàn toàn tab Điểm đón)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vị trí cứu hộ lân cận',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Danh sách các điểm sự cố cứu hộ lân cận
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(items.length, (index) {
                  final item = items[index];
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
                  final isSelected = selectedItemIndex == index;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocationItemTile(
                        icon: Icons.warning_amber_rounded,
                        iconColor: isSelected ? Colors.amber[800]! : Colors.grey,
                        title: item['title'] as String,
                        distance: distanceStr,
                        isSelected: isSelected,
                        onTap: () => onItemTap(index, itemLatLng, item['title'] as String),
                      ),
                      if (index < items.length - 1)
                        const Divider(height: 1, indent: 64),
                    ],
                  );
                }),
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
