import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'package:fe_moblie_flutter/core/services/backend_otp_service.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/pin_code_fields.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

import 'package:fe_moblie_flutter/core/utils/app_alert.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/mechanic_register_info_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:provider/provider.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({
    super.key,
    required this.role,
    required this.mode,
    required this.phoneNumber,
    this.useBackendOtp = false,
    this.initialDebugCode,
    this.resendCooldownSeconds = 60,
  });

  final UserRole role;
  final AuthMode mode;
  final String phoneNumber;
  final bool useBackendOtp;
  /// Mã OTP dev (local) — hiển thị cố định trên màn, không chỉ SnackBar.
  final String? initialDebugCode;
  final int resendCooldownSeconds;

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  late int _secondsLeft;
  bool _verifying = false;
  String? _devOtpCode;

  @override
  void initState() {
    super.initState();
    _devOtpCode = widget.initialDebugCode;
    _secondsLeft = widget.useBackendOtp ? widget.resendCooldownSeconds : 59;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = widget.useBackendOtp ? widget.resendCooldownSeconds : 59;
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
    if (widget.useBackendOtp) {
      try {
        final sent = await context.read<BackendOtpService>().sendOtp(
          widget.phoneNumber,
          purpose: 'register',
        );
        if (!mounted) return;
        setState(() {
          if (sent.debugCode != null) _devOtpCode = sent.debugCode;
        });
        _startTimer();
        AppAlert.showSuccess(
          context,
          sent.debugCode != null ? 'Đã làm mới mã OTP (dev)' : 'Đã gửi lại mã OTP',
        );
      } catch (e) {
        if (mounted) {
          AppAlert.showError(context, errorMessageFrom(e));
        }
      }
    }
  }

  Future<void> _onContinue() async {
    if (_otp.length < 6) {
      AppAlert.showError(context, 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() => _verifying = true);

    if (widget.useBackendOtp) {
      try {
        final verified = await context.read<BackendOtpService>().verifyOtp(
          widget.phoneNumber,
          _otp,
        );
        if (!mounted) return;
        setState(() => _verifying = false);
        if (widget.role == UserRole.mechanic) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MechanicRegisterInfoScreen(
                phoneNumber: widget.phoneNumber,
                otpToken: verified.otpToken,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(
                role: widget.role,
                phoneNumber: widget.phoneNumber,
                otpToken: verified.otpToken,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _verifying = false);
          AppAlert.showError(context, errorMessageFrom(e));
        }
      }
      return;
    }

    if (mounted) {
      setState(() => _verifying = false);
      AppAlert.showError(context, 'OTP chỉ hỗ trợ qua máy chủ SOSbike.');
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
          'Vui lòng nhập',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mã OTP',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.useBackendOtp
              ? 'Mã OTP đã gửi tới $masked'
              : 'Đã gửi SMS tới $masked',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (_devOtpCode != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mã OTP (môi trường dev)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _devOtpCode!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canResend
                      ? 'Có thể gửi lại mã sau khi hết đếm ngược'
                      : 'Gửi lại mã sau $_secondsLeft giây',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
                const TextSpan(text: 'Nhập trong '),
                TextSpan(
                  text: '$_secondsLeft',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' giây'),
              ] else
                const TextSpan(text: 'Bạn có thể gửi lại mã'),
            ],
          ),
        ),
        if (canResend) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resendOtp,
            child: const Text(
              'Gửi lại OTP',
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
            : SosPrimaryButton(label: 'Tiếp Tục', onPressed: _onContinue),
        const SizedBox(height: 20),
        const AuthPageDots(count: 4, activeIndex: 3),
        const SizedBox(height: 24),
      ],
    );
  }
}
