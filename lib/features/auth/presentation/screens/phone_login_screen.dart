import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/otp_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/password_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_mode_switch.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/social_auth_button.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  AuthMode _mode = AuthMode.login;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('84')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '0$digits';
  }

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && digits.length <= 11;
  }

  void _onContinue() {
    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại hợp lệ')),
      );
      return;
    }

    if (widget.role == UserRole.mechanic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thợ máy chưa được hỗ trợ. Vui lòng chọn Người đi xe.'),
        ),
      );
      return;
    }

    if (_mode == AuthMode.register && _nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên')),
      );
      return;
    }

    if (_mode == AuthMode.login) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PasswordLoginScreen(
            role: widget.role,
            mode: AuthMode.login,
            phoneNumber: _normalizedPhone,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpLoginScreen(
            role: widget.role,
            mode: _mode,
            phoneNumber: _normalizedPhone,
            fullName: _nameController.text.trim(),
          ),
        ),
      );
    }
  }

  void _goBack() => authPop(context);

  @override
  Widget build(BuildContext context) {
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
        if (_mode == AuthMode.register) ...[
          const SizedBox(height: 20),
          const Text(
            'Họ và tên',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Nguyễn Văn A'),
          ),
        ],
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
        SosPrimaryButton(label: 'Tiếp tục', onPressed: _onContinue),
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
          iconAsset: 'assets/images/login/google_logo.png',
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
        AuthPageDots(count: _mode == AuthMode.login ? 3 : 4, activeIndex: 1),
        const SizedBox(height: 24),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
