import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _searchTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startSearchingFlow() {
    setState(() {
      _step = FindMechanicStep.searching;
      _searchProgress = 0.0;
    });

    _searchTimer?.cancel();
    _progressTimer?.cancel();

    // Progress bar animation simulation (3 seconds total)
    const duration = Duration(milliseconds: 100);
    const totalSteps = 30; // 30 * 100ms = 3s
    int currentStep = 0;

    _progressTimer = Timer.periodic(duration, (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _searchProgress = currentStep / totalSteps;
        });
      }
      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });

    _searchTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _step = FindMechanicStep.mechanicFound;
        });
      }
    });
  }

  void _cancelSearch() {
    _searchTimer?.cancel();
    _progressTimer?.cancel();
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

  Widget _buildMapBackground() {
    if (_step == FindMechanicStep.locationSelect) {
      return Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
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
        // Draw the red route line on tracking step
        if (_step == FindMechanicStep.tracking)
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(),
            ),
          ),
      ],
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      FindMechanicStep.locationSelect => LocationSelectView(
          onBack: () => Navigator.of(context).pop(),
          onConfirmLocation: _startSearchingFlow,
        ),
      FindMechanicStep.searching => SearchingView(
          progress: _searchProgress,
          onCancel: _cancelSearch,
        ),
      FindMechanicStep.mechanicFound => MechanicFoundView(
          onCancel: _cancelSearch,
          onConfirm: () {
            setState(() {
              _step = FindMechanicStep.tracking;
            });
          },
        ),
      FindMechanicStep.tracking => TrackingView(
          onCancel: () => Navigator.of(context).pop(),
        ),
    };
  }
}

// Custom Painter to draw active tracking line in Step 6
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Simulate route coordinates over the image background
    path.moveTo(size.width * 0.52, size.height * 0.09); // Start point (mechanic)
    path.lineTo(size.width * 0.44, size.height * 0.08);
    path.lineTo(size.width * 0.38, size.height * 0.28);
    path.lineTo(size.width * 0.52, size.height * 0.38);
    path.lineTo(size.width * 0.64, size.height * 0.52);
    path.lineTo(size.width * 0.78, size.height * 0.70);
    path.lineTo(size.width * 0.94, size.height * 0.82); // End point (user)

    canvas.drawPath(path, paint);

    // Draw user location pulse point
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    final pulsePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.09), 16.0, pulsePaint);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.09), 8.0, pointPaint);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.09), 6.0, Paint()..color = Colors.white);

    // Draw mechanic destination point
    canvas.drawCircle(Offset(size.width * 0.94, size.height * 0.82), 20.0, Paint()..color = Colors.red.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(size.width * 0.94, size.height * 0.82), 10.0, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
