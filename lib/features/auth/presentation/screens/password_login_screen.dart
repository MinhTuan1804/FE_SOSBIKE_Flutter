import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/mechanic_register_draft.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';
import 'package:fe_moblie_flutter/core/utils/app_alert.dart';

class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({
    super.key,
    required this.role,
    required this.mode,
    required this.phoneNumber,
    this.fullName,
    this.firebaseIdToken,
    this.otpToken,
    this.identityCard,
    this.licensePlate,
    this.mechanicDraft,
  });

  final UserRole role;
  final AuthMode mode;
  final String phoneNumber;
  final String? fullName;
  final String? firebaseIdToken;
  final String? otpToken;
  final String? identityCard;
  final String? licensePlate;
  final MechanicRegisterDraft? mechanicDraft;

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goBack() => Navigator.of(context).pop();

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      AppAlert.showError(context, 'Mật khẩu tối thiểu 6 ký tự');
      return;
    }

    final auth = context.read<AuthProvider>();
    final bool success;

    if (widget.mode == AuthMode.register) {
      final draft = widget.mechanicDraft;
      success = await auth.register(
        phoneNumber: widget.phoneNumber,
        password: password,
        fullName: draft?.fullName ??
            widget.fullName ??
            (widget.role == UserRole.mechanic ? 'Thợ SOSbike' : 'Khách hàng'),
        userType: widget.role.apiValue,
        firebaseIdToken: widget.firebaseIdToken,
        otpToken: widget.otpToken,
        identityCard: draft?.identityCard ?? widget.identityCard,
        licensePlate: widget.licensePlate,
        currentAddress: draft?.currentAddress,
        dateOfBirth: draft?.dateOfBirth,
        email: draft?.email,
      );
    } else {
      success = await auth.login(widget.phoneNumber, password);
    }

    if (!mounted) return;

    if (!success) {
      AppAlert.showError(context, auth.errorMessage ?? 'Thao tác thất bại');
      return;
    }

    // Upload ảnh xác thực thợ nếu có
    final draft = widget.mechanicDraft;
    if (draft != null && draft.portraitFile != null) {
      await auth.uploadMechanicDocuments(draft);
    }

    if (!mounted) return;
    // AuthGate đổi sang MainShell; chỉ reset root nếu stack cũ còn route auth lỗi.
    completeAuthenticationNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
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
          focusNode: _passwordFocus,
          autofocus: true,
          obscureText: _obscure,
          enableSuggestions: false,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
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
