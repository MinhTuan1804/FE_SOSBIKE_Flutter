import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/utils/image_picker_utils.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

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
  'SHB', 'HDBank', 'SeABank', 'VIB', 'OCB', 'MSB',
];

// ─────────────────────────────────────────────────────────────────────────────
// Màn hình hoàn thiện hồ sơ thợ (sau khi đăng ký, trước khi admin duyệt)
// ─────────────────────────────────────────────────────────────────────────────

class MechanicSetupProfileScreen extends StatefulWidget {
  final int initialTab;
  const MechanicSetupProfileScreen({super.key, this.initialTab = 0});

  @override
  State<MechanicSetupProfileScreen> createState() =>
      _MechanicSetupProfileScreenState();
}

class _MechanicSetupProfileScreenState
    extends State<MechanicSetupProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // ── Khu vực hoạt động (thuật toán quét đơn tự động) ─────────────────────────
  String? _province;
  final _districtCtrl = TextEditingController();

  // ── Xác thực ────────────────────────────────────────────────────────
  XFile? _cccdFront;
  XFile? _cccdBack;
  XFile? _portrait;
  XFile? _certificate;
  String? _existingCccdFrontUrl;
  String? _existingCccdBackUrl;
  String? _existingPortraitUrl;
  String? _existingCertificateUrl;

  // ── Phương tiện ───────────────────────────────────────────────────────
  final _vehicleModelCtrl = TextEditingController();
  final _vehicleGenCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();
  final _driverLicenseNumberCtrl = TextEditingController();
  final _vehicleColorCtrl = TextEditingController();
  XFile? _vehiclePhoto;          // ảnh chụp thực của xe
  XFile? _vehicleRegistration;
  XFile? _vehicleInsurance;
  XFile? _driverLicense;
  String? _existingVehiclePhotoUrl;
  String? _existingVehicleRegistrationUrl;
  String? _existingVehicleInsuranceUrl;
  String? _existingDriverLicenseUrl;

  // ── Ngân hàng ───────────────────────────────────────────────────────
  String? _bankName;
  final _bankAccCtrl = TextEditingController();
  final _bankHolderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this,
        initialIndex: widget.initialTab.clamp(0, 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final profile = auth.profile;
      if (profile != null) {
        setState(() {
          final address = profile.currentAddress;
          if (address != null && address.contains(',')) {
            final parts = address.split(',');
            if (parts.length >= 2) {
              final prov = parts.last.trim();
              if (_kProvinces.contains(prov)) {
                _province = prov;
              }
              _districtCtrl.text = parts.first.trim();
            }
          }

          if (profile.mechanic != null) {
            final mech = profile.mechanic!;
            _existingCccdFrontUrl = mech.cccdFrontUrl;
            _existingCccdBackUrl = mech.cccdBackUrl;
            _existingPortraitUrl = profile.avatarUrl;
            _existingCertificateUrl = mech.certificateUrl;
            _existingVehiclePhotoUrl = mech.vehiclePhotoUrl;
            _existingVehicleRegistrationUrl = mech.vehicleRegistrationUrl;
            _existingVehicleInsuranceUrl = mech.vehicleInsuranceUrl;
            _existingDriverLicenseUrl = mech.driverLicenseUrl;

            _vehicleModelCtrl.text = mech.vehicleModel ?? '';
            _vehicleGenCtrl.text = mech.vehicleGeneration ?? '';
            _licensePlateCtrl.text = mech.licensePlate;
            _driverLicenseNumberCtrl.text = mech.driverLicenseNumber ?? '';
            _vehicleColorCtrl.text = mech.color ?? '';
          }

          if (profile.wallet != null) {
            _bankName = profile.wallet!.bankName;
            _bankAccCtrl.text = profile.wallet!.bankAccountNumber ?? '';
            _bankHolderCtrl.text = profile.wallet!.bankAccountHolder ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _districtCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehicleGenCtrl.dispose();
    _licensePlateCtrl.dispose();
    _driverLicenseNumberCtrl.dispose();
    _vehicleColorCtrl.dispose();
    _bankAccCtrl.dispose();
    _bankHolderCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );

  void _saveAndNext() {
    final tab = _tabCtrl.index;

    if (tab == 0 && _province == null) {
      return _snack('Vui lòng chọn tỉnh/thành phố');
    }
    
    if (tab == 1) {
      final hasCccdFront = _cccdFront != null || (_existingCccdFrontUrl != null && _existingCccdFrontUrl!.isNotEmpty);
      final hasCccdBack = _cccdBack != null || (_existingCccdBackUrl != null && _existingCccdBackUrl!.isNotEmpty);
      final hasPortrait = _portrait != null || (_existingPortraitUrl != null && _existingPortraitUrl!.isNotEmpty);

      if (!hasCccdFront) return _snack('Vui lòng tải ảnh CCCD mặt trước');
      if (!hasCccdBack) return _snack('Vui lòng tải ảnh CCCD mặt sau');
      if (!hasPortrait) return _snack('Vui lòng tải ảnh chân dung');
    }

    if (tab == 2) {
      final model = _vehicleModelCtrl.text.trim();
      final plate = _licensePlateCtrl.text.trim();
      final dlNumber = _driverLicenseNumberCtrl.text.trim();
      final hasReg = _vehicleRegistration != null || (_existingVehicleRegistrationUrl != null && _existingVehicleRegistrationUrl!.isNotEmpty);
      final hasDl = _driverLicense != null || (_existingDriverLicenseUrl != null && _existingDriverLicenseUrl!.isNotEmpty);

      if (model.isEmpty) return _snack('Vui lòng nhập mẫu xe');
      if (plate.isEmpty) return _snack('Vui lòng nhập biển số xe');
      if (dlNumber.isEmpty) return _snack('Vui lòng nhập số bằng lái xe');
      if (!hasReg) return _snack('Vui lòng tải ảnh đăng ký xe (Cà vẹt)');
      if (!hasDl) return _snack('Vui lòng tải ảnh bằng lái xe');
    }

    if (tab == 3) {
      final bankAcc = _bankAccCtrl.text.trim();
      final bankHolder = _bankHolderCtrl.text.trim();
      if (_bankName == null || bankAcc.length < 6 || bankHolder.length < 2) {
        return _snack('Vui lòng điền đầy đủ tài khoản ngân hàng để nhận thanh toán');
      }
    }

    if (tab < 3) {
      _tabCtrl.animateTo(tab + 1);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final success = await auth.setupMechanicProfile(
        province: _province ?? '',
        district: _districtCtrl.text,
        bankName: _bankName ?? '',
        bankAccountNumber: _bankAccCtrl.text,
        bankAccountHolder: _bankHolderCtrl.text,
        portrait: _portrait,
        cccdFront: _cccdFront,
        cccdBack: _cccdBack,
        certificate: _certificate,
        vehicleModel: _vehicleModelCtrl.text,
        vehicleGeneration: _vehicleGenCtrl.text,
        licensePlate: _licensePlateCtrl.text,
        driverLicenseNumber: _driverLicenseNumberCtrl.text,
        vehiclePhoto: _vehiclePhoto,
        vehicleRegistration: _vehicleRegistration,
        vehicleInsurance: _vehicleInsurance,
        driverLicense: _driverLicense,
        color: _vehicleColorCtrl.text.trim().isEmpty ? null : _vehicleColorCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss spinner

      if (success) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hồ sơ đã gửi!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thông tin của bạn đang chờ admin xem xét và phê duyệt.\n'
                  'Thường mất 1–2 ngày làm việc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // close dialog
                      Navigator.of(context).pop(); // pop setup profile screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Về trang chủ',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final err = auth.errorMessage ?? 'Gửi hồ sơ thất bại. Vui lòng thử lại.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _pickPhoto(void Function(XFile?) setter) async {
    final f = await pickImageFromCameraOrGallery(context,
        maxWidth: 1024, imageQuality: 85);
    if (f != null && mounted) setState(() => setter(f));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hoàn thiện hồ sơ thợ',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () async {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
              final auth = context.read<AuthProvider>();
              await auth.fetchMyProfile();
              if (context.mounted) {
                Navigator.of(context).pop(); // dismiss loading dialog
                final isVerified = auth.profile?.mechanic?.isVerified ?? false;
                if (isVerified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài khoản đã được duyệt thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop(); // pop screen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài khoản vẫn đang chờ admin phê duyệt.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            tooltip: 'Kiểm tra trạng thái duyệt',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'Khu vực'),
              Tab(text: 'Xác thực'),
              Tab(text: 'Phương tiện'),
              Tab(text: 'Ngân hàng'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Status banner
          _StatusBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _tabServiceArea(),
                _tabPhotos(),
                _tabVehicle(),
                _tabBank(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        final isLastTab = _tabCtrl.index == 3;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          child: Row(
            children: [
              if (_tabCtrl.index > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () =>
                        _tabCtrl.animateTo(_tabCtrl.index - 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Quay lại',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              if (_tabCtrl.index > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveAndNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isLastTab ? 'Gửi hồ sơ' : 'Tiếp theo',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 1: Chuyên môn ─────────────────────────────────────────────────────

  // ── Tab 1: Khu vực hoạt động ────────────────────────────────────────────────
  // (Bán kính phục vụ & có nhận sửa tận nơi do thuật toán quét đơn BE quyết định)

  Widget _tabServiceArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Tỉnh / Thành phố *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _province,
            isExpanded: true,
            decoration: _dropDeco('Chọn tỉnh/thành'),
            items: _kProvinces
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _province = v),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Quận / Huyện (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(
            controller: _districtCtrl,
            decoration:
                _textDeco('Quận Bình Thạnh, Huyện Củ Chi...'),
          ),
          // Bán kính & "sửa tận nơi" do thuật toán quét đơn bên BE tự động xử lý.
          // Thợ không cần chọn thủ công ở đây.
        ],
      ),
    );
  }

  // ── Tab 3: Xác thực ───────────────────────────────────────────────────────

  Widget _tabPhotos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photoTile(
            icon: Icons.credit_card_outlined,
            label: 'CCCD mặt trước *',
            hint: 'Chụp rõ, đủ 4 góc',
            file: _cccdFront,
            existingUrl: _existingCccdFrontUrl,
            onTap: () => _pickPhoto((f) => _cccdFront = f),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.credit_card,
            label: 'CCCD mặt sau *',
            hint: 'Chụp rõ, đủ 4 góc',
            file: _cccdBack,
            existingUrl: _existingCccdBackUrl,
            onTap: () => _pickPhoto((f) => _cccdBack = f),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.person_outline,
            label: 'Ảnh chân dung *',
            hint: 'Mặt nhìn thẳng, đủ ánh sáng',
            file: _portrait,
            existingUrl: _existingPortraitUrl,
            onTap: () => _pickPhoto((f) => _portrait = f),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Chứng chỉ nghề (tuỳ chọn)',
            hint: 'Honda, Yamaha, trường nghề... nếu có',
            file: _certificate,
            existingUrl: _existingCertificateUrl,
            onTap: () => _pickPhoto((f) => _certificate = f),
            required: false,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFFCC02), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thợ có chứng chỉ được gắn huy hiệu "⭐ Tay nghề xác minh". '
                    'Ảnh sẽ được admin xem xét trong 1–2 ngày làm việc.',
                    style: TextStyle(
                        fontSize: 11.5, color: Color(0xFFE65100)),
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
    required String hint,
    required XFile? file,
    required String? existingUrl,
    required VoidCallback onTap,
    bool required = true,
  }) {
    final hasLocal = file != null;
    final hasRemote = !hasLocal && existingUrl != null && existingUrl.isNotEmpty;
    final has = hasLocal || hasRemote;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: has
              ? AppColors.primary.withValues(alpha: 0.06)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: has ? AppColors.primary : const Color(0xFFE0E0E0),
            width: has ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: has
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasLocal
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FutureBuilder(
                        future: file.readAsBytes(),
                        builder: (_, s) => s.hasData
                            ? Image.memory(s.data!,
                                fit: BoxFit.cover,
                                width: 46,
                                height: 46)
                            : const SizedBox(),
                      ),
                    )
                  : hasRemote
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: existingUrl,
                            fit: BoxFit.cover,
                            width: 46,
                            height: 46,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(icon, size: 22, color: const Color(0xFF9E9E9E)),
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
                      color: has ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(hint,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              has ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: has ? AppColors.primary : const Color(0xFFBDBDBD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Phương tiện ───────────────────────────────────────────────────

  Widget _tabVehicle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Mẫu xe', _vehicleModelCtrl, hint: 'Wave Alpha, Sirius, Vision...', required: true),
          _field('Đời xe (Năm)', _vehicleGenCtrl, hint: '2022', digitsOnly: true),
          _field('Màu xe', _vehicleColorCtrl, hint: 'Đỏ, Đen, Trắng...'),
          _field('Biển số xe', _licensePlateCtrl, hint: '29A1-12345', required: true),
          _field('Số giấy phép lái xe (GPLX)', _driverLicenseNumberCtrl, hint: '12 chữ số', digitsOnly: true, required: true),
          const SizedBox(height: 12),
          // ── Ảnh xe thực (hiển thị ngoài trang hồ sơ) ─────────────────────
          _photoTile(
            icon: Icons.photo_camera_outlined,
            label: 'Ảnh xe của bạn (hiển thị ngoài hồ sơ)',
            hint: 'Chụp ảnh xe rõ nét, góc nghiêng hoặc thẳng',
            file: _vehiclePhoto,
            existingUrl: _existingVehiclePhotoUrl,
            onTap: () => _pickPhoto((f) => setState(() => _vehiclePhoto = f)),
            required: false,
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.directions_bike_outlined,
            label: 'Ảnh đăng ký xe (Cà vẹt) *',
            hint: 'Chụp rõ nét cà vẹt xe',
            file: _vehicleRegistration,
            existingUrl: _existingVehicleRegistrationUrl,
            onTap: () => _pickPhoto((f) => setState(() => _vehicleRegistration = f)),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.security_outlined,
            label: 'Ảnh bảo hiểm xe (Tuỳ chọn)',
            hint: 'Còn hạn sử dụng',
            file: _vehicleInsurance,
            existingUrl: _existingVehicleInsuranceUrl,
            onTap: () => _pickPhoto((f) => setState(() => _vehicleInsurance = f)),
            required: false,
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.badge_outlined,
            label: 'Ảnh bằng lái xe (GPLX) mặt trước *',
            hint: 'Chụp rõ nét bằng lái xe',
            file: _driverLicense,
            existingUrl: _existingDriverLicenseUrl,
            onTap: () => _pickPhoto((f) => setState(() => _driverLicense = f)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Tab 4: Ngân hàng ──────────────────────────────────────────────────────

  Widget _tabBank() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF5350), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFFC62828)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BẮT BUỘC: Phải có tài khoản ngân hàng để nhận thanh toán đơn và tiền di chuyển từ khách. '
                    'Không thể bắt đầu làm việc nếu thiếu thông tin này.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Ngân hàng *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _bankName,
            isExpanded: true,
            decoration: _dropDeco('Chọn ngân hàng nhận tiền'),
            items: _kBanks
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _bankName = v),
          ),
          const SizedBox(height: 16),
          _field('Số tài khoản', _bankAccCtrl,
              hint: '1234567890', digitsOnly: true, required: true),
          _field('Chủ tài khoản', _bankHolderCtrl,
              hint: 'Nguyễn Văn A', required: true),
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isVerified = auth.profile?.mechanic?.isVerified ?? false;
    if (isVerified) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
      ),
      child: Row(
        children: const [
          Icon(Icons.hourglass_top_rounded,
              size: 16, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tài khoản đang chờ admin phê duyệt. '
              'Phải có tài khoản ngân hàng đầy đủ thì mới bắt đầu nhận đơn được.',
              style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

InputDecoration _textDeco(String hint) => InputDecoration(
      hintText: hint,
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
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

Widget _field(
  String label,
  TextEditingController ctrl, {
  String? hint,
  bool digitsOnly = false,
  bool required = false,
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
                      text: ' *', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType:
                digitsOnly ? TextInputType.number : TextInputType.text,
            inputFormatters: digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: _textDeco(hint ?? ''),
          ),
        ],
      ),
    );
