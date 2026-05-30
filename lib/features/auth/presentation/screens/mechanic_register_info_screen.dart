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
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/sos_primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hằng số
// ─────────────────────────────────────────────────────────────────────────────

const _kSpecialties = [
  'Sửa xe máy',
  'Sửa ô tô',
  'Điện xe',
  'Máy gầm / Động cơ',
  'Vá lốp',
  'Cứu hộ',
  'Thay bình ắc quy',
  'Rửa xe',
];

const _kRadiusOptions = [5, 10, 20, 50];

const _kProvinces = [
  'Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
  'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
  'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
  'Bình Thuận', 'Cà Mau', 'Cao Bằng', 'Đắk Lắk', 'Đắk Nông',
  'Điện Biên', 'Đồng Nai', 'Đồng Tháp', 'Gia Lai', 'Hà Giang',
  'Hà Nam', 'Hà Tĩnh', 'Hải Dương', 'Hậu Giang', 'Hòa Bình',
  'Hưng Yên', 'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu',
  'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định',
  'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên',
  'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị',
  'Sóc Trăng', 'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên',
  'Thanh Hóa', 'Thừa Thiên Huế', 'Tiền Giang', 'Trà Vinh', 'Tuyên Quang',
  'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái',
];

const _kBanks = [
  'Vietcombank', 'Techcombank', 'VietinBank', 'BIDV', 'Agribank',
  'MB Bank', 'ACB', 'Sacombank', 'TPBank', 'VPBank',
  'SHB', 'HDBank', 'SeABank', 'VIB', 'OCB', 'MSB', 'NCB',
];

// ─────────────────────────────────────────────────────────────────────────────

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
  final _pageCtrl = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  // Step 1 — Cá nhân
  final _nameCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  DateTime? _dob;

  // Step 2 — Nghề nghiệp
  final Set<String> _specialties = {};
  int? _yearsExp;
  final _descCtrl = TextEditingController();
  bool _availableNow = true;

  // Step 3 — Khu vực
  String? _province;
  final _districtCtrl = TextEditingController();
  int? _radiusKm = 10;
  bool _homeService = true;

  // Step 4 — Xác thực
  XFile? _cccdFront;
  XFile? _cccdBack;
  XFile? _portrait;
  XFile? _certificate;

  // Step 5 — Ngân hàng
  String? _bankName;
  final _bankAccCtrl = TextEditingController();
  final _bankHolderCtrl = TextEditingController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _cccdCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _descCtrl.dispose();
    _districtCtrl.dispose();
    _bankAccCtrl.dispose();
    _bankHolderCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );

  void _goNext() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goPrev() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_nameCtrl.text.trim().length < 2) {
          _snack('Vui lòng nhập họ và tên');
          return false;
        }
        if (_cccdCtrl.text.trim().length < 9) {
          _snack('CCCD/CMND không hợp lệ');
          return false;
        }
        if (_dob == null) {
          _snack('Vui lòng chọn ngày tháng năm sinh');
          return false;
        }
        if (_addressCtrl.text.trim().length < 5) {
          _snack('Vui lòng nhập địa chỉ hiện tại');
          return false;
        }
        return true;
      case 1:
        if (_specialties.isEmpty) {
          _snack('Vui lòng chọn ít nhất 1 chuyên môn');
          return false;
        }
        return true;
      case 2:
        if (_province == null) {
          _snack('Vui lòng chọn tỉnh/thành phố');
          return false;
        }
        return true;
      case 3:
        if (_cccdFront == null) {
          _snack('Vui lòng tải ảnh CCCD mặt trước');
          return false;
        }
        if (_cccdBack == null) {
          _snack('Vui lòng tải ảnh CCCD mặt sau');
          return false;
        }
        if (_portrait == null) {
          _snack('Vui lòng tải ảnh chân dung');
          return false;
        }
        return true;
      case 4:
        // Ngân hàng tuỳ chọn — luôn cho qua
        return true;
      default:
        return true;
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final draft = MechanicRegisterDraft(
      phoneNumber: widget.phoneNumber,
      fullName: name,
      identityCard: _cccdCtrl.text.trim(),
      dateOfBirth: _dob!,
      currentAddress: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      specialties: _specialties.toList(),
      yearsOfExperience: _yearsExp,
      professionalDescription: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      isAvailableNow: _availableNow,
      province: _province,
      district: _districtCtrl.text.trim().isEmpty
          ? null
          : _districtCtrl.text.trim(),
      serviceRadiusKm: _radiusKm,
      hasHomeService: _homeService,
      cccdFrontFile: _cccdFront,
      cccdBackFile: _cccdBack,
      portraitFile: _portrait,
      certificateFile: _certificate,
      shopName: null,
      shopAddress: null,
      bankName: _bankName,
      bankAccountNumber: _bankAccCtrl.text.trim().isEmpty
          ? null
          : _bankAccCtrl.text.trim(),
      bankAccountHolder: _bankHolderCtrl.text.trim().isEmpty
          ? null
          : _bankHolderCtrl.text.trim(),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepBar(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _Step1Personal(
                    phoneDisplay: toLocalVietnamPhone(widget.phoneNumber),
                    nameCtrl: _nameCtrl,
                    cccdCtrl: _cccdCtrl,
                    addressCtrl: _addressCtrl,
                    emailCtrl: _emailCtrl,
                    dob: _dob,
                    onPickDob: _pickDob,
                  ),
                  _Step2Professional(
                    specialties: _specialties,
                    yearsExp: _yearsExp,
                    descCtrl: _descCtrl,
                    availableNow: _availableNow,
                    onSpecialtyToggle: (s) =>
                        setState(() => _specialties.contains(s)
                            ? _specialties.remove(s)
                            : _specialties.add(s)),
                    onYearsExpChanged: (v) => setState(() => _yearsExp = v),
                    onAvailableChanged: (v) =>
                        setState(() => _availableNow = v),
                  ),
                  _Step3ServiceArea(
                    province: _province,
                    districtCtrl: _districtCtrl,
                    radiusKm: _radiusKm,
                    homeService: _homeService,
                    onProvinceChanged: (v) => setState(() => _province = v),
                    onRadiusChanged: (v) => setState(() => _radiusKm = v),
                    onHomeServiceChanged: (v) =>
                        setState(() => _homeService = v),
                  ),
                  _Step4Photos(
                    cccdFront: _cccdFront,
                    cccdBack: _cccdBack,
                    portrait: _portrait,
                    certificate: _certificate,
                    onPickCccdFront: () => _pickPhoto((f) => _cccdFront = f),
                    onPickCccdBack: () => _pickPhoto((f) => _cccdBack = f),
                    onPickPortrait: () => _pickPhoto((f) => _portrait = f),
                    onPickCertificate: () =>
                        _pickPhoto((f) => _certificate = f),
                  ),
                  _Step5Bank(
                    bankName: _bankName,
                    bankAccCtrl: _bankAccCtrl,
                    bankHolderCtrl: _bankHolderCtrl,
                    onBankChanged: (v) => setState(() => _bankName = v),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Thông tin cá nhân',
      'Chuyên môn',
      'Khu vực nhận việc',
      'Xác thực thợ',
      'Tài khoản ngân hàng',
    ];
    final subtitles = [
      'Bước 1 / $_totalSteps',
      'Bước 2 / $_totalSteps',
      'Bước 3 / $_totalSteps',
      'Bước 4 / $_totalSteps — bắt buộc',
      'Bước 5 / $_totalSteps — tuỳ chọn, cập nhật sau',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthBackHeader(onBack: _goPrev),
          const SizedBox(height: 8),
          Text(
            titles[_currentStep],
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitles[_currentStep],
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStepBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.primary
                    : active
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SosPrimaryButton(
        label: isLast ? 'Hoàn tất đăng ký' : 'Tiếp Tục',
        onPressed: _goNext,
      ),
    );
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

  Future<void> _pickPhoto(void Function(XFile?) setter) async {
    final f = await pickImageFromCameraOrGallery(context, maxWidth: 1024, imageQuality: 85);
    if (f != null && mounted) setState(() => setter(f));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Thông tin cá nhân
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Personal extends StatelessWidget {
  const _Step1Personal({
    required this.phoneDisplay,
    required this.nameCtrl,
    required this.cccdCtrl,
    required this.addressCtrl,
    required this.emailCtrl,
    required this.dob,
    required this.onPickDob,
  });

  final String phoneDisplay;
  final TextEditingController nameCtrl;
  final TextEditingController cccdCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController emailCtrl;
  final DateTime? dob;
  final VoidCallback onPickDob;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Họ và tên', nameCtrl, hint: 'Nguyễn Văn A', required: true),
          _readOnly('Số điện thoại', phoneDisplay),
          _field('CCCD / CMND', cccdCtrl,
              hint: '001234567890', digitsOnly: true, required: true),
          _label('Ngày sinh *'),
          GestureDetector(
            onTap: onPickDob,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dob != null
                    ? DateFormat('dd/MM/yyyy').format(dob!)
                    : 'Chọn ngày sinh',
                style: TextStyle(
                  color:
                      dob != null ? AppColors.textPrimary : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field('Địa chỉ hiện tại', addressCtrl,
              hint: 'Số nhà, phường, quận, tỉnh...', required: true),
          _field('Email (tuỳ chọn)', emailCtrl,
              hint: 'example@gmail.com', email: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Nghề nghiệp
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Professional extends StatelessWidget {
  const _Step2Professional({
    required this.specialties,
    required this.yearsExp,
    required this.descCtrl,
    required this.availableNow,
    required this.onSpecialtyToggle,
    required this.onYearsExpChanged,
    required this.onAvailableChanged,
  });

  final Set<String> specialties;
  final int? yearsExp;
  final TextEditingController descCtrl;
  final bool availableNow;
  final void Function(String) onSpecialtyToggle;
  final void Function(int?) onYearsExpChanged;
  final void Function(bool) onAvailableChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Chuyên môn *'),
          const Text(
            'Chọn tất cả dịch vụ bạn có thể làm',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSpecialties.map((s) {
              final selected = specialties.contains(s);
              return FilterChip(
                label: Text(s),
                selected: selected,
                onSelected: (_) => onSpecialtyToggle(s),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color:
                      selected ? AppColors.primary : const Color(0xFFDDDDDD),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Số năm kinh nghiệm'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: yearsExp,
            decoration: _dropDeco('Chọn số năm'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Chưa rõ')),
              ...List.generate(
                31,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(i == 0 ? 'Dưới 1 năm' : '$i năm'),
                ),
              ),
            ],
            onChanged: onYearsExpChanged,
          ),
          const SizedBox(height: 20),
          _sectionLabel('Mô tả ngắn (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(
            controller: descCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText:
                  'Ví dụ: Thợ 5 năm kinh nghiệm, chuyên Honda, có thể lên đường ngay...',
              hintStyle: const TextStyle(fontSize: 13),
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Color(0xFF4CAF50)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sẵn sàng nhận việc ngay',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Hệ thống sẽ ưu tiên phân đơn cho thợ Online',
                          style: TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: availableNow,
                  onChanged: onAvailableChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Khu vực nhận việc
// ─────────────────────────────────────────────────────────────────────────────

class _Step3ServiceArea extends StatelessWidget {
  const _Step3ServiceArea({
    required this.province,
    required this.districtCtrl,
    required this.radiusKm,
    required this.homeService,
    required this.onProvinceChanged,
    required this.onRadiusChanged,
    required this.onHomeServiceChanged,
  });

  final String? province;
  final TextEditingController districtCtrl;
  final int? radiusKm;
  final bool homeService;
  final void Function(String?) onProvinceChanged;
  final void Function(int?) onRadiusChanged;
  final void Function(bool) onHomeServiceChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Tỉnh / Thành phố *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: province,
            isExpanded: true,
            decoration: _dropDeco('Chọn tỉnh/thành'),
            items: _kProvinces
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: onProvinceChanged,
          ),
          const SizedBox(height: 20),
          _sectionLabel('Quận / Huyện (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(
            controller: districtCtrl,
            decoration: InputDecoration(
              hintText: 'Quận Bình Thạnh, Huyện Củ Chi...',
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
          const SizedBox(height: 20),
          _sectionLabel('Bán kính phục vụ'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _kRadiusOptions.map((r) {
              final selected = radiusKm == r;
              return ChoiceChip(
                label: Text('$r km'),
                selected: selected,
                onSelected: (_) => onRadiusChanged(r),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color:
                      selected ? AppColors.primary : const Color(0xFFDDDDDD),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_repair_service_outlined,
                    size: 22, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nhận sửa tận nơi',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Thợ sẵn sàng đến địa điểm khách hàng',
                          style: TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: homeService,
                  onChanged: onHomeServiceChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Xác thực thợ
// ─────────────────────────────────────────────────────────────────────────────

class _Step4Photos extends StatelessWidget {
  const _Step4Photos({
    required this.cccdFront,
    required this.cccdBack,
    required this.portrait,
    required this.certificate,
    required this.onPickCccdFront,
    required this.onPickCccdBack,
    required this.onPickPortrait,
    required this.onPickCertificate,
  });

  final XFile? cccdFront;
  final XFile? cccdBack;
  final XFile? portrait;
  final XFile? certificate;
  final VoidCallback onPickCccdFront;
  final VoidCallback onPickCccdBack;
  final VoidCallback onPickPortrait;
  final VoidCallback onPickCertificate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photoTile(
            icon: Icons.credit_card_outlined,
            label: 'Ảnh CCCD mặt trước *',
            subtitle: 'Chụp rõ, đủ 4 góc, không mờ',
            file: cccdFront,
            onTap: onPickCccdFront,
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.credit_card,
            label: 'Ảnh CCCD mặt sau *',
            subtitle: 'Chụp rõ, đủ 4 góc, không mờ',
            file: cccdBack,
            onTap: onPickCccdBack,
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.person_outline,
            label: 'Ảnh chân dung *',
            subtitle: 'Mặt nhìn thẳng, đủ ánh sáng',
            file: portrait,
            onTap: onPickPortrait,
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Chứng chỉ nghề (tuỳ chọn)',
            subtitle: 'Honda, Yamaha, trường nghề... nếu có',
            file: certificate,
            onTap: onPickCertificate,
            required: false,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC02), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ảnh sẽ được xem xét để xác minh tài khoản thợ. '
                    'Thợ có chứng chỉ được gắn huy hiệu "⭐ Tay nghề xác minh".',
                    style:
                        TextStyle(fontSize: 11.5, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required XFile? file,
    required VoidCallback onTap,
    bool required = true,
  }) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.primary.withValues(alpha: 0.06)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? AppColors.primary : const Color(0xFFE0E0E0),
            width: hasFile ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FutureBuilder(
                        future: file.readAsBytes(),
                        builder: (c, s) => s.hasData
                            ? Image.memory(s.data!,
                                fit: BoxFit.cover, width: 44, height: 44)
                            : const SizedBox(),
                      ),
                    )
                  : Icon(icon, size: 22, color: const Color(0xFF9E9E9E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: hasFile ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: hasFile ? AppColors.primary : const Color(0xFFBDBDBD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Tài khoản ngân hàng (tuỳ chọn)
// ─────────────────────────────────────────────────────────────────────────────

class _Step5Bank extends StatelessWidget {
  const _Step5Bank({
    required this.bankName,
    required this.bankAccCtrl,
    required this.bankHolderCtrl,
    required this.onBankChanged,
  });

  final String? bankName;
  final TextEditingController bankAccCtrl;
  final TextEditingController bankHolderCtrl;
  final void Function(String?) onBankChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                    'Thông tin ngân hàng dùng để nhận tiền khi hoàn thành đơn. '
                    'Bạn có thể bỏ qua và cập nhật sau trong phần Hồ sơ.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF3B82F6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Ngân hàng'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: bankName,
            isExpanded: true,
            decoration: _dropDeco('Chọn ngân hàng'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Bỏ qua')),
              ..._kBanks.map(
                  (b) => DropdownMenuItem(value: b, child: Text(b))),
            ],
            onChanged: onBankChanged,
          ),
          const SizedBox(height: 16),
          _field('Số tài khoản', bankAccCtrl,
              hint: '1234567890', digitsOnly: true),
          _field('Chủ tài khoản', bankHolderCtrl,
              hint: 'Nguyễn Văn A'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionLabel(String text) => Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

InputDecoration _dropDeco(String hint) => InputDecoration(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );

Widget _readOnly(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
  bool upperCase = false,
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
            textCapitalization: upperCase
                ? TextCapitalization.characters
                : TextCapitalization.none,
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
