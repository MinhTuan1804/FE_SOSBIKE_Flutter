import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/constants/app_assets.dart';
import 'package:fe_moblie_flutter/core/navigation/app_navigator.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/intro_welcome_screen.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/screens/main_shell_screen.dart';

/// Màn khởi động: chờ token → shell chính hoặc luồng đăng nhập (navigator con).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _authFailsafe;
  final GlobalKey<NavigatorState> _authFlowNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();

    _authFailsafe = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      context.read<AuthProvider>().forceAuthReady();
    });
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();
    if (!mounted) return;
    auth.forceAuthReady();
    _repairRootStackIfNeeded();
  }

  /// Stack cũ (push auth lên root, mất AuthGate): gộp về một route AuthGate.
  void _repairRootStackIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = appNavigatorKey.currentState;
      if (nav == null || !nav.canPop()) return;
      resetToAuthGate();
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

        // Luồng đăng nhập chỉ trên navigator con — không đè lên AuthGate ở root.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _authFlowNavKey.currentState?.maybePop();
          },
          child: Navigator(
            key: _authFlowNavKey,
            initialRoute: '/intro',
            onGenerateRoute: (settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const IntroWelcomeScreen(),
              );
            },
          ),
        );
      },
    );
  }
}

class _AuthBootSplash extends StatelessWidget {
  const _AuthBootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.logo,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
