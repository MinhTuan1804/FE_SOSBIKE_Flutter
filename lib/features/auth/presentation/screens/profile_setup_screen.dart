import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

/// MÃ n hÃ¬nh nháº­p thÃ´ng tin cÆ¡ báº£n sau khi xÃ¡c thá»±c OTP thÃ nh cÃ´ng (Ä‘Äƒng kÃ½).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

enum Gender { male, female, other }

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();

  DateTime? _selectedDob;
  Gender? _selectedGender;
  File? _avatarFile;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('Lá»—i chá»n áº£nh: $e');
    }
  }

  void _goBack() => authPop(context);

  String get _genderLabel {
    switch (_selectedGender) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Ná»¯';
      case Gender.other:
        return 'KhÃ¡c';
      default:
        return 'Chá»n giá»›i tÃ­nh';
    }
  }

  String get _genderApiValue {
    switch (_selectedGender) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
      case Gender.other:
        return 'OTHER';
      default:
        return '';
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  bool _isEmailValid(String email) {
    if (email.isEmpty) return true; // Email khÃ´ng báº¯t buá»™c
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lÃ²ng nháº­p há» vÃ  tÃªn (Ã­t nháº¥t 2 kÃ½ tá»±)')),
      );
      return;
    }

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lÃ²ng chá»n ngÃ y sinh')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lÃ²ng chá»n giá»›i tÃ­nh')),
      );
      return;
    }

    if (!_isEmailValid(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email khÃ´ng há»£p lá»‡')),
      );
      return;
    }

    setState(() => _saving = true);

    final authProvider = context.read<AuthProvider>();

    // á»ž bÆ°á»›c nÃ y, user Ä‘Ã£ qua OTP nhÆ°ng chÆ°a Ä‘Æ°á»£c lÆ°u vÃ o database.
    // Firebase auth token váº«n cÃ²n, ta láº¥y sÄ‘t tá»« Firebase
    final firebaseUser = authProvider.user == null ? FirebaseAuth.instance.currentUser : null;
    final phone = firebaseUser?.phoneNumber ?? '';

    // Gá»i hÃ m Register Ä‘á»ƒ chÃ­nh thá»©c táº¡o user trong há»‡ thá»‘ng BE
    final success = await authProvider.register(
      phoneNumber: phone,
      password: 'firebase_auth_no_password',
      fullName: name,
      userType: 'CUSTOMER',
      email: email.isNotEmpty ? email : null,
      firebaseIdToken: await firebaseUser?.getIdToken(),
    );

    if (success) {
      // Náº¿u Ä‘Äƒng kÃ½ thÃ nh cÃ´ng, tuá»³ chá»n cáº­p nháº­t thÃªm ngÃ y sinh, giá»›i tÃ­nh, avatar
      await authProvider.updateProfile(
        fullName: name,
        dateOfBirth: _selectedDob!,
        gender: _genderApiValue,
        email: email.isNotEmpty ? email : null,
        referralCode: _referralController.text.trim().isNotEmpty
            ? _referralController.text.trim()
            : null,
        avatarFile: _avatarFile,
      );
    }

    if (mounted) setState(() => _saving = false);

    if (success) {
      if (mounted) navigateToHome();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'ÄÄƒng kÃ½ há»“ sÆ¡ tháº¥t báº¡i'),
          ),
        );
      }
    }
  }

  // â”€â”€ Reusable input decoration â”€â”€
  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
    );
  }

  // â”€â”€ Field label â”€â”€
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      children: [
        AuthBackHeader(onBack: _goBack),
        const SizedBox(height: 24),

        // â”€â”€ Avatar â”€â”€
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE8EAED),
                  backgroundImage:
                      _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? const Icon(Icons.person,
                          size: 50, color: Color(0xFF9E9E9E))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // â”€â”€ Há» vÃ  TÃªn â”€â”€
        _label('Há» vÃ  TÃªn'),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration('Tráº§n KhÃ¡nh Linh'),
        ),

        const SizedBox(height: 20),

        // â”€â”€ NgÃ y sinh â”€â”€
        _label('NgÃ y sinh'),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDob != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
                      : 'Chá»n ngÃ y sinh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedDob != null
                        ? AppColors.textPrimary
                        : Colors.grey.shade400,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // â”€â”€ Giá»›i tÃ­nh â”€â”€
        _label('Giá»›i tÃ­nh'),
        Row(
          children: Gender.values.map((g) {
            final isSelected = _selectedGender == g;
            String label;
            switch (g) {
              case Gender.male:
                label = 'Nam';
              case Gender.female:
                label = 'Ná»¯';
              case Gender.other:
                label = 'KhÃ¡c';
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: g != Gender.other ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // â”€â”€ Email â”€â”€
        _label('Email'),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(
            'example@email.com',
            suffixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // â”€â”€ MÃ£ giá»›i thiá»‡u â”€â”€
        _label('MÃ£ giá»›i thiá»‡u (náº¿u cÃ³)'),
        TextField(
          controller: _referralController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          decoration: _fieldDecoration(
            'Nháº­p mÃ£ giá»›i thiá»‡u',
            suffixIcon: const Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 36),

        // â”€â”€ NÃºt Tiáº¿p Tá»¥c â”€â”€
        _saving
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SosPrimaryButton(label: 'Tiáº¿p Tá»¥c', onPressed: _onContinue),

        const SizedBox(height: 20),
        const AuthPageDots(count: 4, activeIndex: 3),
        const SizedBox(height: 24),
      ],
    );
  }
}
