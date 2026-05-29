import 'package:flutter/material.dart';

/// Nền gradient đỏ cho màn hình chính (thợ).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  static const assetPath = 'assets/images/main/background.png';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC02020), Color(0xFF2A0808)],
            ),
          ),
        ),
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        child,
      ],
    );
  }
}
