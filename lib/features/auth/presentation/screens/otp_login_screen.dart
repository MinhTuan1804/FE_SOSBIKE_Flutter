import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/services/backend_otp_service.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/password_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/pin_code_fields.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({
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
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  BackendOtpService? _otpService;

  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 59;
  bool _sending = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  BackendOtpService get _otpSvc =>
      _otpService ??= context.read<BackendOtpService>();

  Future<void> _sendOtp({bool resend = false}) async {
    setState(() {
      _sending = true;
      _error = null;
      if (resend) _secondsLeft = 59;
    });

    try {
      final result = await _otpSvc.sendOtp(widget.phoneNumber);
      if (!mounted) return;
      setState(() => _sending = false);
      if (!resend) _startTimer();

      if (result.debugCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'DEV: Mã OTP ${result.debugCode} (chưa cấu hình ESMS trên server)',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString();
      });
    }
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

  Future<void> _goToPassword({required String otpToken}) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PasswordLoginScreen(
          role: widget.role,
          mode: widget.mode,
          phoneNumber: widget.phoneNumber,
          fullName: widget.fullName,
          otpToken: otpToken,
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 số OTP')),
      );
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final result = await _otpSvc.verifyOtp(widget.phoneNumber, _otp);
      if (!mounted) return;
      await _goToPassword(otpToken: result.otpToken);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = widget.phoneNumber;
    final canResend = !_sending && _secondsLeft <= 0;

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
          'Đã gửi SMS tới $masked',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (_sending) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text(
            'Đang gửi mã OTP...',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ] else ...[
          const SizedBox(height: 28),
          PinCodeFields(
            controllers: _controllers,
            focusNodes: _focusNodes,
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          if (_error != null) const SizedBox(height: 8),
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
              onPressed: () => _sendOtp(resend: true),
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
          SosPrimaryButton(
            label: 'Tiếp Tục',
            isLoading: _verifying,
            onPressed: (_sending || _verifying) ? null : _onContinue,
          ),
        ],
        const SizedBox(height: 20),
        const AuthPageDots(count: 4, activeIndex: 2),
        const SizedBox(height: 24),
      ],
    );
  }
}
