import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/constants/app_assets.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

/// Màn Mở đầu (Figma) — logo, slogan, nút Bắt đầu.
class IntroWelcomeScreen extends StatelessWidget {
  const IntroWelcomeScreen({super.key});

  void _onStart(BuildContext context) {
    // Dùng push — KHÔNG pushReplacement (sẽ xóa AuthGate khỏi stack, login xong phải F5).
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                AppAssets.logo,
                width: 147,
                height: 147,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 147,
                  height: 147,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler, size: 72, color: Colors.white),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'SOSBIKE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CHĂM XE TẬN NƠI,\nTHẢNH THƠI VẠN DẶM!',
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.35,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hệ sinh thái chăm sóc và cứu hộ xe máy\nchủ động 24/7 của Việt Nam',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
              ),
              const Spacer(flex: 3),
              SosPrimaryButton(
                label: 'Bắt đầu',
                showArrow: true,
                onPressed: () => _onStart(context),
              ),
              const SizedBox(height: 22),
              const AuthPageDots(count: 4, activeIndex: 0),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
