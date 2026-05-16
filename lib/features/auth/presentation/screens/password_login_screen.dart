import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({
    super.key,
    required this.role,
    required this.mode,
    required this.phoneNumber,
    this.fullName,
  });

  final UserRole role;
  final AuthMode mode;
  final String phoneNumber;
  final String? fullName;

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _passwordController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 29;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 29;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  void _goBack() => Navigator.of(context).pop();

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu tối thiểu 6 ký tự')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final bool success;

    if (widget.mode == AuthMode.register) {
      success = await auth.register(
        phoneNumber: widget.phoneNumber,
        password: password,
        fullName: widget.fullName ?? 'Khách hàng',
        userType: widget.role.apiValue,
      );
    } else {
      success = await auth.login(widget.phoneNumber, password);
    }

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Thao tác thất bại')),
      );
      return;
    }

    navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      children: [
        AuthBackHeader(onBack: _goBack),
        const SizedBox(height: 32),
        Text(
          widget.mode.label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vui lòng nhập',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mật khẩu của bạn',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chữ và số, tối thiểu 6 ký tự',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu',
            filled: true,
            fillColor: AppColors.pinFill,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'Nhập trong '),
              TextSpan(
                text: '$_secondsLeft',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' giây'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SosPrimaryButton(
              label: 'Tiếp Tục',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            );
          },
        ),
        const SizedBox(height: 20),
        AuthPageDots(
          count: widget.mode == AuthMode.login ? 3 : 4,
          activeIndex: widget.mode == AuthMode.login ? 2 : 3,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
