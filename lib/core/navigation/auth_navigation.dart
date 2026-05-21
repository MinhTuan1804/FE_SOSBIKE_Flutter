import 'package:fe_moblie_flutter/core/navigation/app_navigator.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_gate.dart';
import 'package:flutter/material.dart';

/// Đặt lại navigator gốc về một route [AuthGate] duy nhất.
void resetToAuthGate() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
    (route) => false,
  );
}

/// Sau đăng nhập / đăng ký xong — luôn đặt lại root (kể cả stack cũ chỉ còn "Bạn là ai?").
void completeAuthenticationNavigation() => resetToAuthGate();

void navigateToHome() => completeAuthenticationNavigation();

void navigateToLogin() => resetToAuthGate();
