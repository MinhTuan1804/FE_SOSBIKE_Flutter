import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/widgets/location_select_view.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/widgets/searching_view.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/widgets/mechanic_found_view.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/widgets/tracking_view.dart';

enum FindMechanicStep {
  locationSelect,
  searching,
  mechanicFound,
  tracking,
}

class FindMechanicFlowPage extends StatefulWidget {
  const FindMechanicFlowPage({super.key});

  @override
  State<FindMechanicFlowPage> createState() => _FindMechanicFlowPageState();
}

class _FindMechanicFlowPageState extends State<FindMechanicFlowPage> {
  FindMechanicStep _step = FindMechanicStep.locationSelect;
  Timer? _searchTimer;
  double _searchProgress = 0.0;
  Timer? _progressTimer;

  GoogleMapController? _flowMapController;
  BitmapDescriptor? _mechanicIcon;
  BitmapDescriptor? _customerIcon;

  Future<void> _loadCustomMarkerIcons() async {
    try {
      _mechanicIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(38, 38)),
        'assets/images/onboarding/logo.png',
      );
      _customerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RescueProvider>().addListener(_onRescueProviderChanged);
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<RescueProvider>().removeListener(_onRescueProviderChanged);
    } catch (_) {}
    _searchTimer?.cancel();
    _progressTimer?.cancel();
    _flowMapController?.dispose();
    super.dispose();
  }

  void _onRescueProviderChanged() {
    if (!mounted) return;
    final rescue = context.read<RescueProvider>();
    if (rescue.matchedMechanic != null && _step == FindMechanicStep.searching) {
      _searchTimer?.cancel();
      _progressTimer?.cancel();
      setState(() {
        _step = FindMechanicStep.mechanicFound;
      });
    }
  }

  Future<void> _confirmLocation(double lat, double lng, String address) async {
    setState(() {
      _step = FindMechanicStep.searching;
      _searchProgress = 0.0;
    });

    _searchTimer?.cancel();
    _progressTimer?.cancel();

    // Slowly progress search bar visually to mimic wait
    const duration = Duration(milliseconds: 500);
    int ticks = 0;
    _progressTimer = Timer.periodic(duration, (timer) {
      ticks++;
      if (mounted) {
        setState(() {
          _searchProgress = (ticks / 30).clamp(0.0, 0.92);
        });
      }
    });

    final success = await context.read<RescueProvider>().createRescueOrder(
      latitude: lat,
      longitude: lng,
      requestAddress: address,
      locationNote: null,
    );

    if (!success && mounted) {
      _progressTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<RescueProvider>().errorMessage ?? 'Không thể gửi yêu cầu cứu hộ.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _step = FindMechanicStep.locationSelect;
      });
    }
  }

  void _cancelSearch() {
    _searchTimer?.cancel();
    _progressTimer?.cancel();
    context.read<RescueProvider>().cancelSearch();
    setState(() {
      _step = FindMechanicStep.locationSelect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Base Map Background for map steps
          if (_step == FindMechanicStep.locationSelect ||
              _step == FindMechanicStep.mechanicFound ||
              _step == FindMechanicStep.tracking)
            Positioned.fill(
              child: _buildMapBackground(),
            ),

          // Custom content overlay based on current step
          Positioned.fill(
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }

  void _fitBounds(double custLat, double custLng, double mechLat, double mechLng) {
    if (_flowMapController == null) return;
    
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
    
    _flowMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  Widget _buildMapBackground() {
    if (_step == FindMechanicStep.locationSelect) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final rescue = context.watch<RescueProvider>();
    final match = rescue.matchedMechanic;
    
    final double custLat = rescue.customerLatitude ?? 10.762622;
    final double custLng = rescue.customerLongitude ?? 106.660172;
    
    double? mechLat;
    double? mechLng;
    if (match != null) {
      mechLat = match['mechanicLatitude'] != null ? (match['mechanicLatitude'] as num).toDouble() : null;
      mechLng = match['mechanicLongitude'] != null ? (match['mechanicLongitude'] as num).toDouble() : null;
    }

    if (mechLat != null && mechLng != null) {
      final customerLatLng = LatLng(custLat, custLng);
      final mechanicLatLng = LatLng(mechLat, mechLng);

      final markers = {
        Marker(
          markerId: const MarkerId('customer'),
          position: customerLatLng,
          icon: _customerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
        ),
        Marker(
          markerId: const MarkerId('mechanic'),
          position: mechanicLatLng,
          icon: _mechanicIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: match?['mechanicName'] ?? 'Thợ sửa xe'),
        ),
      };

      final polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: rescue.activeRoutePoints.isNotEmpty
              ? rescue.activeRoutePoints
              : [customerLatLng, mechanicLatLng],
          color: const Color(0xFFC02020),
          width: 5,
        ),
      };

      if (_flowMapController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds(custLat, custLng, mechLat!, mechLng!);
        });
      }

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: customerLatLng,
          zoom: 14.0,
        ),
        markers: markers,
        polylines: polylines,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        onMapCreated: (controller) {
          _flowMapController = controller;
          Future.delayed(const Duration(milliseconds: 200), () {
            _fitBounds(custLat, custLng, mechanicLatLng.latitude, mechanicLatLng.longitude);
          });
        },
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/main/map_card.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.map, size: 80, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      FindMechanicStep.locationSelect => LocationSelectView(
          onBack: () => Navigator.of(context).pop(),
          onConfirmLocation: _confirmLocation,
        ),
      FindMechanicStep.searching => SearchingView(
          progress: _searchProgress,
          onCancel: _cancelSearch,
        ),
      FindMechanicStep.mechanicFound => MechanicFoundView(
          onCancel: _cancelSearch,
          onConfirm: () async {
            final orderId = context.read<RescueProvider>().currentOrderId;
            if (orderId != null) {
              await context.read<RescueProvider>().confirmOrder(orderId);
            }
            setState(() {
              _step = FindMechanicStep.tracking;
            });
          },
        ),
      FindMechanicStep.tracking => TrackingView(
          onCancel: () {
            _cancelSearch();
            Navigator.of(context).pop();
          },
        ),
    };
  }
}


