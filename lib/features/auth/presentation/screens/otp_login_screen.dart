import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/pin_code_fields.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:provider/provider.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({
    super.key,
    required this.role,
    required this.mode,
    required this.phoneNumber,
  });

  final UserRole role;
  final AuthMode mode;
  final String phoneNumber;

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 59;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 59;
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _goBack() => Navigator.of(context).pop();

  String get masked {
    if (widget.phoneNumber.length < 4) return widget.phoneNumber;
    return '******${widget.phoneNumber.substring(widget.phoneNumber.length - 4)}';
  }

  bool get canResend => _secondsLeft == 0;

  Future<void> _resendOtp() async {
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _secondsLeft = 59;
    });
    _startTimer();

    await authProvider.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ÄÃ£ gá»­i láº¡i mÃ£ OTP thÃ nh cÃ´ng')),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
    );
  }

  Future<void> _onContinue() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lÃ²ng nháº­p Ä‘á»§ 6 sá»‘ OTP')),
      );
      return;
    }

    setState(() => _verifying = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      _otp,
      userType: widget.role.name.toUpperCase(),
      isRegister: widget.mode == AuthMode.register,
    );

    if (mounted) setState(() => _verifying = false);

    if (success) {
      if (mounted) {
        if (widget.mode == AuthMode.register) {
          // ÄÄƒng kÃ½: chuyá»ƒn sang nháº­p thÃ´ng tin cÆ¡ báº£n
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProfileSetupScreen(),
            ),
          );
        } else {
          // ÄÄƒng nháº­p: vÃ o tháº³ng trang chÃ­nh
          navigateToHome();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'XÃ¡c thá»±c OTP tháº¥t báº¡i')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
          'Vui lÃ²ng nháº­p',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Text(
          'MÃ£ OTP',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ÄÃ£ gá»­i SMS tá»›i $masked',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        PinCodeFields(
          controllers: _controllers,
          focusNodes: _focusNodes,
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            children: [
              if (_secondsLeft > 0) ...[
                const TextSpan(text: 'Nháº­p trong '),
                TextSpan(
                  text: '$_secondsLeft',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' giÃ¢y'),
              ] else
                const TextSpan(text: 'Báº¡n cÃ³ thá»ƒ gá»­i láº¡i mÃ£'),
            ],
          ),
        ),
        if (canResend) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resendOtp,
            child: const Text(
              'Gá»­i láº¡i OTP',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        authProvider.isLoading || _verifying
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SosPrimaryButton(label: 'Tiáº¿p Tá»¥c', onPressed: _onContinue),
        const SizedBox(height: 20),
        const AuthPageDots(count: 4, activeIndex: 2),
        const SizedBox(height: 24),
      ],
    );
  }
}
