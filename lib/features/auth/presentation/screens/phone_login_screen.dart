import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/utils/phone_utils.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/backend_phone_auth.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/mechanic_register_info_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/otp_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/password_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_mode_switch.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/social_auth_button.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';
import 'package:provider/provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  AuthMode _mode = AuthMode.login;
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('84')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+84$digits';
  }

  bool get _isPhoneValid => isValidVietnamPhone(_phoneController.text);

  void _onContinue() async {
    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Số điện thoại không hợp lệ. Dùng số VN 10 số (vd: 0912345678, 0977999888)',
          ),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final localPhone = toLocalVietnamPhone(_phoneController.text);

    // 1. Check if phone exists in the backend
    final phoneExists = await authProvider.checkPhoneExists(localPhone);

    if (phoneExists == null) {
      if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    // 2. Validate based on Mode
    if (_mode == AuthMode.login && !phoneExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại chưa được đăng ký với hệ thống')),
        );
      }
      return;
    }

    if (_mode == AuthMode.register && phoneExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại này đã được đăng ký trong DB')),
        );
      }
      return;
    }

    // Web / API local (dev): SĐT + mật khẩu BE, không Firebase SMS
    if (useBackendPhoneAuth) {
      if (_mode == AuthMode.login) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PasswordLoginScreen(
              role: widget.role,
              mode: _mode,
              phoneNumber: localPhone,
            ),
          ),
        );
        return;
      }

      // Dev/local BE: đăng ký không cần OTP (Otp:RequireForRegister=false)
      if (!mounted) return;
      if (widget.role == UserRole.mechanic) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MechanicRegisterInfoScreen(phoneNumber: localPhone),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PasswordLoginScreen(
              role: widget.role,
              mode: _mode,
              phoneNumber: localPhone,
            ),
          ),
        );
      }
      return;
    }

    // Mobile: Firebase SMS OTP
    authProvider.verifyPhoneNumber(
      phoneNumber: _normalizedPhone,
      onCodeSent: (verificationId) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpLoginScreen(
              role: widget.role,
              mode: _mode,
              phoneNumber: _normalizedPhone,
            ),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  void _goBack() => authPop(context);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthFormLayout(
      children: [
        AuthBackHeader(onBack: _goBack),
        const SizedBox(height: 24),
        AuthModeSwitch(
          mode: _mode,
          onChanged: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: 28),
        Text(
          _mode == AuthMode.login ? 'Đăng nhập' : 'Đăng ký',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _mode == AuthMode.login
              ? 'Nhập số điện thoại đã đăng ký'
              : 'Tạo tài khoản mới bằng số điện thoại',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        const Text(
          'Số điện thoại',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDA251D), Color(0xFFFFCD00)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('+84', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.socialBorder),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '0977999888',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onSubmitted: (_) => _onContinue(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        authProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SosPrimaryButton(label: 'Tiếp tục', onPressed: _onContinue),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Hoặc', style: TextStyle(color: Colors.grey.shade600)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 16),
        SocialAuthButton(
          label: 'Đăng nhập bằng Google',
          iconAsset: 'assets/images/login/btn_google.png',
          border: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng nhập Google — sắp có')),
            );
          },
        ),
        const SizedBox(height: 10),
        SocialAuthButton(
          label: 'Đăng nhập bằng Facebook',
          icon: Icons.facebook,
          background: const Color(0xFFE8F1FF),
          foreground: const Color(0xFF1877F2),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng nhập Facebook — sắp có')),
            );
          },
        ),
        const SizedBox(height: 10),
        SocialAuthButton(
          label: 'Đăng nhập bằng Apple',
          icon: Icons.apple,
          background: Colors.black,
          foreground: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng nhập Apple — sắp có')),
            );
          },
        ),
        const SizedBox(height: 20),
        AuthPageDots(count: _mode == AuthMode.login ? 3 : 4, activeIndex: 2),
        const SizedBox(height: 24),
      ],
    );
  }
}
