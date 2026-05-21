import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/utils/phone_utils.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/core/widgets/app_network_image.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_document_upload_tile.dart';
import 'package:fe_moblie_flutter/features/profile/data/models/user_profile_models.dart';

/// Xem và cập nhật thông tin tài khoản đang đăng nhập.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _generationController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankHolderController = TextEditingController();

  DateTime? _dob;
  String? _phoneDisplay;
  String? _identityCard;
  bool _isMechanic = false;
  bool _loaded = false;

  XFile? _newPortrait;
  XFile? _newRegistration;
  XFile? _newInsurance;
  String? _existingAvatarUrl;
  String? _existingRegistrationUrl;
  String? _existingInsuranceUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _plateController.dispose();
    _vehicleController.dispose();
    _generationController.dispose();
    _driverLicenseController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final profile = await auth.fetchMyProfile();
    if (!mounted) return;
    if (profile == null) {
      _snack(auth.errorMessage ?? 'Không tải được hồ sơ');
      return;
    }
    _applyProfile(profile);
    setState(() => _loaded = true);
  }

  void _applyProfile(UserProfileDto p) {
    _isMechanic = p.isMechanic;
    _phoneDisplay = toLocalVietnamPhone(p.phoneNumber);
    _existingAvatarUrl = p.avatarUrl;
    _nameController.text = p.fullName;
    _emailController.text = p.email ?? '';
    _addressController.text = p.currentAddress ?? '';
    _dob = p.dateOfBirth;

    final m = p.mechanic;
    if (m != null) {
      _identityCard = m.identityCard;
      _plateController.text = m.licensePlate;
      _vehicleController.text = m.vehicleModel ?? '';
      _generationController.text = m.vehicleGeneration ?? '';
      _driverLicenseController.text = m.driverLicenseNumber ?? '';
      _existingRegistrationUrl = m.vehicleRegistrationUrl;
      _existingInsuranceUrl = m.vehicleInsuranceUrl;
    }

    final w = p.wallet;
    if (w != null) {
      _bankNameController.text = w.bankName ?? '';
      _bankAccountController.text = w.bankAccountNumber ?? '';
      _bankHolderController.text = w.bankAccountHolder ?? '';
    }
  }

  void _viewImage(String url, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          height: 420,
          child: InteractiveViewer(
            child: AppNetworkImage(
              url: url,
              fit: BoxFit.contain,
              errorWidget: const Center(
                child: Text(
                  'Không tải được ảnh.\nKiểm tra BE đang chạy (port 5200).',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
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
    if (picked != null && mounted) setState(() => _newPortrait = picked);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < 2) return _snack('Vui lòng nhập họ và tên');

    final auth = context.read<AuthProvider>();
    final ok = await auth.saveMyProfile(
      fullName: name,
      dateOfBirth: _dob,
      email: _emailController.text.trim().isEmpty ? '' : _emailController.text.trim(),
      currentAddress: _addressController.text.trim(),
      licensePlate: _isMechanic ? _plateController.text.trim().toUpperCase() : null,
      vehicleModel: _isMechanic ? _vehicleController.text.trim() : null,
      vehicleGeneration: _isMechanic ? _generationController.text.trim() : null,
      driverLicenseNumber: _isMechanic ? _driverLicenseController.text.trim() : null,
      bankName: _bankNameController.text.trim(),
      bankAccountNumber: _bankAccountController.text.trim(),
      bankAccountHolder: _bankHolderController.text.trim(),
      avatarFile: _newPortrait,
      vehicleRegistration: _newRegistration,
      vehicleInsurance: _newInsurance,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin')),
      );
      Navigator.of(context).pop();
    } else {
      _snack(auth.errorMessage ?? 'Lưu thất bại');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Hồ sơ của tôi', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_newPortrait == null &&
                                _existingAvatarUrl != null &&
                                _existingAvatarUrl!.isNotEmpty) {
                              _viewImage(_existingAvatarUrl!, 'Ảnh chân dung');
                            } else {
                              _pickPortrait();
                            }
                          },
                          onLongPress: _pickPortrait,
                          child: Stack(
                            children: [
                              SizedBox(
                                width: 96,
                                height: 96,
                                child: _buildAvatar() ??
                                    const CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Color(0xFFE8EAED),
                                      child: Icon(Icons.person, size: 48, color: Color(0xFF9E9E9E)),
                                    ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty
                              ? 'Chạm xem ảnh — giữ lâu để đổi'
                              : 'Chạm để tải ảnh chân dung',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field('Họ và tên', _nameController, required: true),
                      _readOnly('Số điện thoại', _phoneDisplay ?? ''),
                      if (_isMechanic && _identityCard != null)
                        _readOnly('CCCD / CMND', _identityCard!),
                      _label('Ngày tháng năm sinh'),
                      GestureDetector(
                        onTap: _pickDob,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _dob != null
                                ? DateFormat('dd/MM/yyyy').format(_dob!)
                                : 'Chọn ngày sinh',
                            style: TextStyle(
                              color: _dob != null ? AppColors.textPrimary : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field('Địa chỉ hiện tại', _addressController),
                      _field('Email (nếu có)', _emailController, email: true),
                      if (_isMechanic) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Thông tin xe & giấy tờ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _field('Biển số xe', _plateController, upperCase: true),
                        _field('Loại xe', _vehicleController),
                        _field('Đời xe', _generationController),
                        _field('Số bằng lái xe', _driverLicenseController),
                        const SizedBox(height: 8),
                        const Text(
                          'Tài khoản ngân hàng nhận tiền',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _field('Tên ngân hàng', _bankNameController),
                        _field('Số tài khoản', _bankAccountController, digitsOnly: true),
                        _field('Chủ tài khoản', _bankHolderController),
                        const SizedBox(height: 12),
                        AuthDocumentUploadTile(
                          label: 'Ảnh cà vẹt xe',
                          required: false,
                          hint: 'Để trống nếu không đổi. Chụp rõ giấy đăng ký xe.',
                          file: _newRegistration,
                          existingImageUrl: _existingRegistrationUrl,
                          onViewExisting: _existingRegistrationUrl != null
                              ? () => _viewImage(_existingRegistrationUrl!, 'Cà vẹt xe')
                              : null,
                          onChanged: (f) => setState(() => _newRegistration = f),
                        ),
                        const SizedBox(height: 12),
                        AuthDocumentUploadTile(
                          label: 'Ảnh bảo hiểm xe',
                          required: false,
                          hint: 'Để trống nếu không đổi. Chụp rõ giấy bảo hiểm.',
                          file: _newInsurance,
                          existingImageUrl: _existingInsuranceUrl,
                          onViewExisting: _existingInsuranceUrl != null
                              ? () => _viewImage(_existingInsuranceUrl!, 'Bảo hiểm xe')
                              : null,
                          onChanged: (f) => setState(() => _newInsurance = f),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: auth.isLoading ? null : _logout,
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget? _buildAvatar() {
    if (_newPortrait != null) {
      return FutureBuilder(
        future: _newPortrait!.readAsBytes(),
        builder: (c, s) {
          if (!s.hasData) return const Icon(Icons.person, size: 48);
          return ClipOval(
            child: Image.memory(s.data!, width: 96, height: 96, fit: BoxFit.cover),
          );
        },
      );
    }
    final url = _existingAvatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: AppNetworkImage(
          url: url,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorWidget: const Icon(Icons.person, size: 48),
        ),
      );
    }
    return null;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
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
    bool required = false,
    bool email = false,
    bool upperCase = false,
    bool digitsOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label *' : label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: email
                ? TextInputType.emailAddress
                : digitsOnly
                    ? TextInputType.number
                    : TextInputType.text,
            inputFormatters: [
              if (upperCase) UpperCaseTextFormatter(),
              if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
