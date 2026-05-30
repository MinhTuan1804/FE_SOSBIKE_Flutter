import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/utils/image_picker_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kSpecialties = [
  'Sửa xe máy', 'Sửa ô tô', 'Điện xe', 'Máy gầm / Động cơ',
  'Vá lốp', 'Cứu hộ', 'Thay bình ắc quy', 'Rửa xe',
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
  'SHB', 'HDBank', 'SeABank', 'VIB', 'OCB', 'MSB',
];

// ─────────────────────────────────────────────────────────────────────────────
// Màn hình hoàn thiện hồ sơ thợ (sau khi đăng ký, trước khi admin duyệt)
// ─────────────────────────────────────────────────────────────────────────────

class MechanicSetupProfileScreen extends StatefulWidget {
  const MechanicSetupProfileScreen({super.key});

  @override
  State<MechanicSetupProfileScreen> createState() =>
      _MechanicSetupProfileScreenState();
}

class _MechanicSetupProfileScreenState
    extends State<MechanicSetupProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // ── Chuyên môn ──────────────────────────────────────────────────────
  final Set<String> _specialties = {};
  int? _yearsExp;
  final _descCtrl = TextEditingController();
  bool _availableNow = true;

  // ── Khu vực ─────────────────────────────────────────────────────────
  String? _province;
  final _districtCtrl = TextEditingController();
  int _radius = 10;
  bool _homeService = true;

  // ── Xác thực ────────────────────────────────────────────────────────
  XFile? _cccdFront;
  XFile? _cccdBack;
  XFile? _portrait;
  XFile? _certificate;

  // ── Ngân hàng ───────────────────────────────────────────────────────
  String? _bankName;
  final _bankAccCtrl = TextEditingController();
  final _bankHolderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _descCtrl.dispose();
    _districtCtrl.dispose();
    _bankAccCtrl.dispose();
    _bankHolderCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );

  void _saveAndNext() {
    final tab = _tabCtrl.index;

    if (tab == 0 && _specialties.isEmpty) {
      return _snack('Vui lòng chọn ít nhất 1 chuyên môn');
    }
    if (tab == 1 && _province == null) {
      return _snack('Vui lòng chọn tỉnh/thành phố');
    }
    if (tab == 2) {
      if (_cccdFront == null) return _snack('Vui lòng tải ảnh CCCD mặt trước');
      if (_cccdBack == null) return _snack('Vui lòng tải ảnh CCCD mặt sau');
      if (_portrait == null) return _snack('Vui lòng tải ảnh chân dung');
    }

    if (tab < 3) {
      _tabCtrl.animateTo(tab + 1);
    } else {
      _submit();
    }
  }

  void _submit() {
    // TODO: gọi API lưu thông tin hồ sơ thợ khi BE sẵn sàng
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
                  Navigator.of(context).pop(); // đóng dialog
                  Navigator.of(context).pop(); // back về dashboard
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
              Tab(text: 'Chuyên môn'),
              Tab(text: 'Khu vực'),
              Tab(text: 'Xác thực'),
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
                _tabSpecialty(),
                _tabServiceArea(),
                _tabPhotos(),
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
    final isLast = _tabCtrl.index == 3;
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

  Widget _tabSpecialty() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Chuyên môn *'),
          const SizedBox(height: 4),
          const Text('Chọn tất cả dịch vụ bạn có thể làm',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSpecialties.map((s) {
              final sel = _specialties.contains(s);
              return FilterChip(
                label: Text(s),
                selected: sel,
                onSelected: (_) => setState(() =>
                    sel ? _specialties.remove(s) : _specialties.add(s)),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: sel ? AppColors.primary : AppColors.textPrimary,
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
                side: BorderSide(
                    color: sel
                        ? AppColors.primary
                        : const Color(0xFFDDDDDD)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Số năm kinh nghiệm'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _yearsExp,
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
            onChanged: (v) => setState(() => _yearsExp = v),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Mô tả ngắn (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: _textDeco(
                'Ví dụ: Thợ Honda 5 năm, chuyên điện và máy gầm...'),
          ),
          const SizedBox(height: 16),
          _onlineTile(),
        ],
      ),
    );
  }

  Widget _onlineTile() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          fontSize: 11.5,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch.adaptive(
              value: _availableNow,
              onChanged: (v) => setState(() => _availableNow = v),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      );

  // ── Tab 2: Khu vực ────────────────────────────────────────────────────────

  Widget _tabServiceArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Tỉnh / Thành phố *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _province,
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
          const SizedBox(height: 20),
          _sectionLabel('Bán kính phục vụ'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _kRadiusOptions.map((r) {
              final sel = _radius == r;
              return ChoiceChip(
                label: Text('$r km'),
                selected: sel,
                onSelected: (_) => setState(() => _radius = r),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                    color: sel
                        ? AppColors.primary
                        : const Color(0xFFDDDDDD)),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text('Thợ sẵn sàng đến địa điểm khách hàng',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _homeService,
                  onChanged: (v) => setState(() => _homeService = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
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
            onTap: () => _pickPhoto((f) => _cccdFront = f),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.credit_card,
            label: 'CCCD mặt sau *',
            hint: 'Chụp rõ, đủ 4 góc',
            file: _cccdBack,
            onTap: () => _pickPhoto((f) => _cccdBack = f),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.person_outline,
            label: 'Ảnh chân dung *',
            hint: 'Mặt nhìn thẳng, đủ ánh sáng',
            file: _portrait,
            onTap: () => _pickPhoto((f) => _portrait = f),
          ),
          const SizedBox(height: 12),
          _photoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Chứng chỉ nghề (tuỳ chọn)',
            hint: 'Honda, Yamaha, trường nghề... nếu có',
            file: _certificate,
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
    required VoidCallback onTap,
    bool required = true,
  }) {
    final has = file != null;
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
              child: has
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
                    'Bạn có thể bỏ qua và cập nhật sau trong Hồ sơ.',
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
            value: _bankName,
            isExpanded: true,
            decoration: _dropDeco('Chọn ngân hàng'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Bỏ qua')),
              ..._kBanks.map(
                  (b) => DropdownMenuItem(value: b, child: Text(b))),
            ],
            onChanged: (v) => setState(() => _bankName = v),
          ),
          const SizedBox(height: 16),
          _field('Số tài khoản', _bankAccCtrl,
              hint: '1234567890', digitsOnly: true),
          _field('Chủ tài khoản', _bankHolderCtrl,
              hint: 'Nguyễn Văn A'),
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              'Hãy hoàn thiện hồ sơ để được duyệt nhanh hơn.',
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
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
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
