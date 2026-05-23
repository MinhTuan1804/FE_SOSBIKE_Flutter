import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/utils/phone_utils.dart';
import 'package:fe_moblie_flutter/features/auth/domain/auth_mode.dart';
import 'package:fe_moblie_flutter/features/auth/domain/mechanic_register_draft.dart';
import 'package:fe_moblie_flutter/features/auth/domain/user_role.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/screens/password_login_screen.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_back_header.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_page_dots.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

/// Đăng ký thợ — form thông tin theo yêu cầu nghiệp vụ.
class MechanicRegisterInfoScreen extends StatefulWidget {
  const MechanicRegisterInfoScreen({
    super.key,
    required this.phoneNumber,
    this.otpToken,
  });

  final String phoneNumber;
  final String? otpToken;

  @override
  State<MechanicRegisterInfoScreen> createState() => _MechanicRegisterInfoScreenState();
}

class _MechanicRegisterInfoScreenState extends State<MechanicRegisterInfoScreen> {
  final _nameController = TextEditingController();
  final _identityController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankHolderController = TextEditingController();

  DateTime? _dob;
  XFile? _portraitFile;

  @override
  void dispose() {
    _nameController.dispose();
    _identityController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _bankHolderController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _pickPortrait() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _portraitFile = picked);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _onContinue() {
    final name = _nameController.text.trim();
    final identity = _identityController.text.trim();
    final address = _addressController.text.trim();
    final bankAcc = _bankAccountController.text.trim();

    if (name.length < 2) return _snack('Vui lòng nhập họ và tên');
    if (identity.length < 6) return _snack('CCCD/CMND không hợp lệ');
    if (_dob == null) return _snack('Vui lòng chọn ngày tháng năm sinh');
    if (address.length < 5) return _snack('Vui lòng nhập địa chỉ hiện tại');
    if (bankAcc.length < 6) return _snack('Vui lòng nhập số tài khoản ngân hàng');
    if (_portraitFile == null) return _snack('Vui lòng tải ảnh chân dung');

    final draft = MechanicRegisterDraft(
      phoneNumber: widget.phoneNumber,
      fullName: name,
      identityCard: identity,
      dateOfBirth: _dob!,
      currentAddress: address,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
      bankAccountNumber: bankAcc,
      bankAccountHolder: _bankHolderController.text.trim().isEmpty ? name : _bankHolderController.text.trim(),
      portraitFile: _portraitFile,
      // Những thông tin xe tạm thời bỏ trống hoặc gán giá trị mặc định theo yêu cầu
      licensePlate: 'N/A',
      vehicleModel: 'N/A',
      vehicleGeneration: 'N/A',
      driverLicenseNumber: 'N/A',
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
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Điền đầy đủ thông tin để hoàn tất đăng ký',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickPortrait,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFE8EAED),
                  child: _portraitFile == null
                      ? const Icon(Icons.person, size: 44, color: Color(0xFF9E9E9E))
                      : ClipOval(
                          child: FutureBuilder(
                            future: _portraitFile!.readAsBytes(),
                            builder: (c, s) => s.hasData
                                ? Image.memory(s.data!, width: 88, height: 88, fit: BoxFit.cover)
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
                      color: const Color(0xFF4CAF50),
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
        const SizedBox(height: 8),
        const Center(
          child: Text('Ảnh chân dung *', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 20),
        _field('Họ và tên', _nameController, hint: 'Nguyễn Văn A', required: true),
        _readOnly('Số điện thoại', phoneDisplay),
        _field('CCCD / CMND', _identityController, hint: '001234567890', digitsOnly: true, required: true),
        _label('Ngày tháng năm sinh *'),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _dob != null ? DateFormat('dd/MM/yyyy').format(_dob!) : 'Chọn ngày sinh',
              style: TextStyle(
                color: _dob != null ? AppColors.textPrimary : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _field('Địa chỉ hiện tại', _addressController, hint: 'Số nhà, phường, quận, tỉnh...', required: true),
        _field('Email (nếu có)', _emailController, hint: 'example@email.com', email: true),
        const SizedBox(height: 8),
        const Text('Tài khoản ngân hàng nhận tiền', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _field('Tên ngân hàng', _bankNameController, hint: 'Vietcombank, Techcombank...'),
        _field('Số tài khoản', _bankAccountController, hint: '1234567890', digitsOnly: true, required: true),
        _field('Chủ tài khoản', _bankHolderController, hint: 'Trùng họ tên hoặc để trống'),
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
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    bool digitsOnly = false,
    bool email = false,
    bool upperCase = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              children: [
                TextSpan(text: label),
                if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: digitsOnly ? TextInputType.number : (email ? TextInputType.emailAddress : TextInputType.text),
            textCapitalization: upperCase ? TextCapitalization.characters : TextCapitalization.none,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
