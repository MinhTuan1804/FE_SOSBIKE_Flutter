import 'package:flutter/material.dart';

/// Map nền + tuỳ chọn vẽ tuyến đường (Figma).
class MechanicOrderMapBackground extends StatelessWidget {
  const MechanicOrderMapBackground({
    super.key,
    this.showRoute = false,
    this.showUserPulse = true,
  });

  final bool showRoute;
  final bool showUserPulse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/main/map_card.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE8EAED),
            child: const Center(child: Icon(Icons.map_outlined, size: 64, color: Colors.grey)),
          ),
        ),
        if (showRoute)
          const Positioned.fill(
            child: CustomPaint(painter: MechanicRoutePainter()),
          ),
        if (showUserPulse && !showRoute)
          const Align(
            alignment: Alignment(0, -0.35),
            child: _MapUserPulse(),
          ),
      ],
    );
  }
}

class MechanicRoutePainter extends CustomPainter {
  const MechanicRoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = const Color(0xFFC02020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.52, size.height * 0.12)
      ..lineTo(size.width * 0.44, size.height * 0.14)
      ..lineTo(size.width * 0.38, size.height * 0.32)
      ..lineTo(size.width * 0.52, size.height * 0.42)
      ..lineTo(size.width * 0.64, size.height * 0.55)
      ..lineTo(size.width * 0.78, size.height * 0.72)
      ..lineTo(size.width * 0.9, size.height * 0.84);

    canvas.drawPath(path, routePaint);

    _drawPulse(canvas, Offset(size.width * 0.52, size.height * 0.12), const Color(0xFF2563EB));
    _drawDot(canvas, Offset(size.width * 0.9, size.height * 0.84), const Color(0xFFC02020));
  }

  void _drawPulse(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 16, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(center, 8, Paint()..color = color);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  void _drawDot(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 18, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(center, 9, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapUserPulse extends StatefulWidget {
  const _MapUserPulse();

  @override
  State<_MapUserPulse> createState() => _MapUserPulseState();
}

class _MapUserPulseState extends State<_MapUserPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34 + t * 24,
              height: 34 + t * 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.22 * (1 - t)),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ],
        );
      },
    );
  }
}
