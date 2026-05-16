import 'package:fe_moblie_flutter/core/navigation/app_navigator.dart';

/// Đóng luồng đăng nhập/đăng ký và quay về [AuthGate] (route gốc).
void navigateToHome() {
  appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
}

void navigateToLogin() {
  appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
}
