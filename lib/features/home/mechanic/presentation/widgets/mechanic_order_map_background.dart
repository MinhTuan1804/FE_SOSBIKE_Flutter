import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';

/// Map nền live Google Map + tuỳ chọn vẽ tuyến đường và hiển thị marker thợ & khách.
class MechanicOrderMapBackground extends StatefulWidget {
  const MechanicOrderMapBackground({
    super.key,
    this.customerLatitude,
    this.customerLongitude,
    this.showRoute = false,
    this.showUserPulse = true,
    this.zoomOutFactor = 1.35,
  });

  final double? customerLatitude;
  final double? customerLongitude;
  final bool showRoute;
  final bool showUserPulse;
  /// >1 = hiển thị nhiều vùng bản đồ hơn (zoom out), vẫn phủ kín khung.
  final double zoomOutFactor;

  static const _mapAsset = 'assets/images/main/map_card.png';

  @override
  State<MechanicOrderMapBackground> createState() => _MechanicOrderMapBackgroundState();
}

class _MechanicOrderMapBackgroundState extends State<MechanicOrderMapBackground> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _mechanicIcon;
  BitmapDescriptor? _customerIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcons();
  }

  Future<void> _loadCustomMarkerIcons() async {
    try {
      _mechanicIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(38, 38)),
        'assets/images/onboarding/logo.png',
      );
      _customerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading custom markers in mechanic map: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitBounds(double custLat, double custLng, double mechLat, double mechLng) {
    if (_mapController == null) return;
    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          custLat < mechLat ? custLat : mechLat,
          custLng < mechLng ? custLng : mechLng,
        ),
        northeast: LatLng(
          custLat > mechLat ? custLat : mechLat,
          custLng > mechLng ? custLng : mechLng,
        ),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 70),
      );
    } catch (e) {
      debugPrint('Error fitting map bounds in mechanic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();

    // Fallbacks to center of HCMC if coordinates are null
    final double custLat = widget.customerLatitude ?? 10.765622;
    final double custLng = widget.customerLongitude ?? 106.663172;

    final double mechLat = rescue.mechanicLatitude ?? 10.762622;
    final double mechLng = rescue.mechanicLongitude ?? 106.660172;

    final customerLatLng = LatLng(custLat, custLng);
    final mechanicLatLng = LatLng(mechLat, mechLng);

    final markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: customerLatLng,
        icon: _customerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Khách hàng'),
      ),
      Marker(
        markerId: const MarkerId('mechanic'),
        position: mechanicLatLng,
        icon: _mechanicIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
      ),
    };

    final polylines = widget.showRoute
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              points: rescue.activeRoutePoints.isNotEmpty
                  ? rescue.activeRoutePoints
                  : [customerLatLng, mechanicLatLng],
              color: const Color(0xFFC02020),
              width: 5,
            ),
          }
        : <Polyline>{};

    if (_mapController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(custLat, custLng, mechLat, mechLng);
      });
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: mechanicLatLng,
        zoom: 14.0,
      ),
      markers: markers,
      polylines: polylines,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        Future.delayed(const Duration(milliseconds: 200), () {
          _fitBounds(custLat, custLng, mechLat, mechLng);
        });
      },
    );
  }
}

