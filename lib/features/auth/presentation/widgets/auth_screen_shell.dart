import 'package:flutter/material.dart';

/// Đảm bảo nút back hệ thống Android/iOS pop đúng stack Navigator.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      child: child,
    );
  }
}

void authPop(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}
