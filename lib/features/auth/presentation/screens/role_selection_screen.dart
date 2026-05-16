import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_pattern_background.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/role_option_button.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.mechanic;

  void _onNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhoneLoginScreen(role: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      child: Scaffold(
      body: AuthPatternBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const Text(
                  'Bạn là ai?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
                const Spacer(flex: 2),
                RoleOptionButton(
                  label: UserRole.customer.label,
                  icon: Icons.sports_motorsports_outlined,
                  selected: _selectedRole == UserRole.customer,
                  onTap: () => setState(() => _selectedRole = UserRole.customer),
                ),
                const SizedBox(height: 16),
                RoleOptionButton(
                  label: UserRole.mechanic.label,
                  icon: Icons.build_outlined,
                  selected: _selectedRole == UserRole.mechanic,
                  onTap: () => setState(() => _selectedRole = UserRole.mechanic),
                ),
                const Spacer(flex: 3),
                SosPrimaryButton(
                  label: 'Tiếp theo',
                  showArrow: true,
                  onPressed: _onNext,
                ),
                const SizedBox(height: 20),
                const AuthPageDots(count: 4, activeIndex: 0),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
