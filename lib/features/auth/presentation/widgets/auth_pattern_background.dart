import 'package:flutter/material.dart';

class AuthPatternBackground extends StatelessWidget {
  const AuthPatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        Opacity(
          opacity: 0.35,
          child: Image.asset(
            'assets/images/login/pattern_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child,
      ],
    );
  }
}
