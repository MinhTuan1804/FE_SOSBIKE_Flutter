import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/navigation/app_navigator.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:fe_moblie_flutter/features/home/presentation/screens/home_screen.dart';

void navigateToHome() {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (_) => false,
  );
}

void navigateToLogin() {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    (_) => false,
  );
}
