import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:fe_moblie_flutter/features/home/presentation/screens/main_shell_screen.dart';

/// Màn khởi động: chờ kiểm tra token, rồi hiển thị đăng nhập hoặc shell chính.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _authFailsafe;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    auth.checkAuthStatus();

    _authFailsafe = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      auth.forceAuthReady();
    });
  }

  @override
  void dispose() {
    _authFailsafe?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.authReady) {
          return const _AuthBootSplash();
        }
        if (auth.isAuthenticated) {
          return const MainShellScreen();
        }
        return const RoleSelectionScreen();
      },
    );
  }
}

class _AuthBootSplash extends StatelessWidget {
  const _AuthBootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOSbike',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
