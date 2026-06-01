import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/utils/image_picker_utils.dart';
import 'package:fe_moblie_flutter/core/utils/phone_utils.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/mechanic_register_draft.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/password_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

/// Đăng ký thợ — chỉ thu thập thông tin cơ bản tối thiểu.
/// Chuyên môn, khu vực, ảnh xác thực, ngân hàng → hoàn thiện sau trong app.
class MechanicRegisterInfoScreen extends StatefulWidget {
  const MechanicRegisterInfoScreen({
    super.key,
    required this.phoneNumber,
    this.otpToken,
  });

  final String phoneNumber;
  final String? otpToken;

  @override
  State<MechanicRegisterInfoScreen> createState() =>
      _MechanicRegisterInfoScreenState();
}

class _MechanicRegisterInfoScreenState
    extends State<MechanicRegisterInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  DateTime? _dob;
  XFile? _portrait;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cccdCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );

  Future<void> _pickPortrait() async {
    final f = await pickImageFromCameraOrGallery(context,
        maxWidth: 512, imageQuality: 85);
    if (f != null && mounted) setState(() => _portrait = f);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  void _onContinue() {
    final name = _nameCtrl.text.trim();
    final cccd = _cccdCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.length < 2) return _snack('Vui lòng nhập họ và tên');
    if (cccd.length < 9) return _snack('CCCD/CMND không hợp lệ');
    if (_dob == null) return _snack('Vui lòng chọn ngày sinh');
    if (address.length < 5) return _snack('Vui lòng nhập địa chỉ hiện tại');

    final draft = MechanicRegisterDraft(
      phoneNumber: widget.phoneNumber,
      fullName: name,
      identityCard: cccd,
      dateOfBirth: _dob!,
      currentAddress: address,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      portraitFile: _portrait,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PasswordLoginScreen(
          role: UserRole.mechanic,
          mode: AuthMode.register,
          phoneNumber: widget.phoneNumber,
          otpToken: widget.otpToken,
          mechanicDraft: draft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneDisplay = toLocalVietnamPhone(widget.phoneNumber);

    return AuthFormLayout(
      children: [
        AuthBackHeader(onBack: () => Navigator.of(context).pop()),
        const SizedBox(height: 12),
        const Text(
          'Thông tin thợ',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Điền thông tin để tạo tài khoản thợ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        // Ghi chú các bước sau
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sau khi đăng ký, bạn phải hoàn thiện hồ sơ thợ '
                  '(chuyên môn + tài khoản ngân hàng bắt buộc) trong app '
                  'và chờ admin duyệt trước khi có thể nhận việc.',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Ảnh chân dung (tuỳ chọn) ──────────────────────────────────
        Center(
          child: GestureDetector(
            onTap: _pickPortrait,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFE8EAED),
                  child: _portrait == null
                      ? const Icon(Icons.person, size: 44, color: Color(0xFF9E9E9E))
                      : ClipOval(
                          child: FutureBuilder(
                            future: _portrait!.readAsBytes(),
                            builder: (c, s) => s.hasData
                                ? Image.memory(s.data!,
                                    width: 88, height: 88, fit: BoxFit.cover)
                                : const Icon(Icons.person),
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Ảnh đại diện (tuỳ chọn)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // ── Các trường bắt buộc ────────────────────────────────────────
        _field('Họ và tên', _nameCtrl, hint: 'Nguyễn Văn A', required: true),
        _readOnly('Số điện thoại', phoneDisplay),
        _field('CCCD / CMND', _cccdCtrl,
            hint: '001234567890', digitsOnly: true, required: true),
        _label('Ngày sinh *'),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _dob != null
                  ? DateFormat('dd/MM/yyyy').format(_dob!)
                  : 'Chọn ngày sinh',
              style: TextStyle(
                color: _dob != null
                    ? AppColors.textPrimary
                    : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _field('Địa chỉ hiện tại', _addressCtrl,
            hint: 'Số nhà, phường, quận, tỉnh...', required: true),
        _field('Email (tuỳ chọn)', _emailCtrl,
            hint: 'example@gmail.com', email: true),

        const SizedBox(height: 28),
        SosPrimaryButton(label: 'Tiếp Tục', onPressed: _onContinue),
        const SizedBox(height: 16),
        const AuthPageDots(count: 4, activeIndex: 3),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool required = false,
    bool digitsOnly = false,
    bool email = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                children: [
                  TextSpan(text: label),
                  if (required)
                    const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: digitsOnly
                  ? TextInputType.number
                  : (email
                      ? TextInputType.emailAddress
                      : TextInputType.text),
              inputFormatters:
                  digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      );
}
