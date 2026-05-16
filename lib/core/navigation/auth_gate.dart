import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/role_selection_screen.dart';

/// Màn khởi động: nếu đã có token thì vào Home, không thì luồng đăng nhập.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfLoggedIn());
  }

  Future<void> _redirectIfLoggedIn() async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      navigateToHome();
    }
  }

  @override
  Widget build(BuildContext context) => const RoleSelectionScreen();
}
