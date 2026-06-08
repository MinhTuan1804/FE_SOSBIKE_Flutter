import 'package:flutter/material.dart';

import 'package:fe_moblie_flutter/core/data/models/vietnam_address_selection.dart';
import 'package:fe_moblie_flutter/core/data/models/vietnam_admin_unit.dart';
import 'package:fe_moblie_flutter/core/data/vietnam_address_repository.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

enum VietnamAddressPickerMode {
  /// Tỉnh → Quận → Phường + số nhà/đường (profile khách).
  full,

  /// Tỉnh → Quận (khu vực thợ).
  serviceArea,
}

enum VietnamAddressPickerStyle {
  filled,
  outlined,
}

class VietnamAddressPicker extends StatefulWidget {
  const VietnamAddressPicker({
    super.key,
    required this.onChanged,
    this.mode = VietnamAddressPickerMode.full,
    this.style = VietnamAddressPickerStyle.filled,
    this.initialSelection,
    this.initialAddress,
    this.districtOptional = false,
    this.showStreetDetail = true,
    this.streetHint = 'Số nhà, tên đường...',
    this.sectionTitle,
    this.provinceLabel = 'Tỉnh / Thành phố',
    this.districtLabel = 'Quận / Huyện',
    this.wardLabel = 'Phường / Xã',
    this.streetLabel = 'Số nhà, đường',
    this.provinceRequired = true,
    this.spacing = 12.0,
    this.streetSuffixIcon,
  });

  final ValueChanged<VietnamAddressSelection> onChanged;
  final VietnamAddressPickerMode mode;
  final VietnamAddressPickerStyle style;
  final VietnamAddressSelection? initialSelection;
  final String? initialAddress;
  final bool districtOptional;
  final bool showStreetDetail;
  final String streetHint;
  final String? sectionTitle;
  final String provinceLabel;
  final String districtLabel;
  final String wardLabel;
  final String streetLabel;
  final bool provinceRequired;
  final double spacing;
  final Widget? streetSuffixIcon;

  @override
  State<VietnamAddressPicker> createState() => _VietnamAddressPickerState();
}

class _VietnamAddressPickerState extends State<VietnamAddressPicker> {
  final _repo = VietnamAddressRepository.instance;
  final _streetCtrl = TextEditingController();

  List<VietnamProvince> _provinces = [];
  List<VietnamDistrict> _districts = [];
  List<VietnamWard> _wards = [];

  VietnamAddressSelection _selection = const VietnamAddressSelection();
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final provinces = await _repo.loadProvinces();
      if (!mounted) return;

      var selection = widget.initialSelection ??
          _repo.parseAddress(widget.initialAddress) ??
          const VietnamAddressSelection();

      if (selection.provinceCode != null) {
        _districts = _repo.districtsOf(selection.provinceCode!);
        if (selection.districtCode != null) {
          _wards = _repo.wardsOf(selection.districtCode!);
        }
      }

      _streetCtrl.text = selection.streetDetail ?? '';

      setState(() {
        _provinces = provinces;
        _selection = selection;
        _loading = false;
      });
      _emit();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Không tải được dữ liệu địa chỉ. Thử tải lại trang (Ctrl+Shift+R).';
        _loading = false;
      });
    }
  }

  void _emit() {
    widget.onChanged(
      _selection.copyWith(
        streetDetail: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
      ),
    );
  }

  void _onProvinceChanged(int code) {
    final province = _provinces.firstWhere((p) => p.code == code);
    setState(() {
      _selection = VietnamAddressSelection(
        provinceCode: province.code,
        provinceName: province.name,
      );
      _districts = province.districts;
      _wards = [];
    });
    _emit();
  }

  void _onDistrictChanged(int code) {
    final district = _districts.firstWhere((d) => d.code == code);
    setState(() {
      _selection = _selection.copyWith(
        districtCode: district.code,
        districtName: district.name,
        clearWard: true,
      );
      _wards = district.wards;
    });
    _emit();
  }

  void _onWardChanged(int code) {
    final ward = _wards.firstWhere((w) => w.code == code);
    setState(() {
      _selection = _selection.copyWith(
        wardCode: ward.code,
        wardName: ward.name,
      );
    });
    _emit();
  }

  Future<int?> _openPickerSheet({
    required String title,
    required List<({int code, String name})> items,
    int? selectedCode,
  }) async {
    final searchCtrl = TextEditingController();
    var filtered = List<({int code, String name})>.from(items);

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void applyFilter(String query) {
              final q = query.trim().toLowerCase();
              setModalState(() {
                filtered = q.isEmpty
                    ? List<({int code, String name})>.from(items)
                    : items.where((e) => e.name.toLowerCase().contains(q)).toList();
              });
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.72,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: applyFilter,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Không tìm thấy kết quả'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final selected = item.code == selectedCode;
                                return ListTile(
                                  title: Text(item.name),
                                  trailing: selected
                                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                                      : null,
                                  onTap: () => Navigator.pop(ctx, item.code),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    if (widget.style == VietnamAddressPickerStyle.outlined) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
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
    );
  }

  Widget _selectField({
    required String label,
    required String? value,
    required String hint,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IgnorePointer(
        child: InputDecorator(
          decoration: _fieldDecoration(label, hint: hint).copyWith(
            suffixIcon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? AppColors.primary : Colors.grey.shade400,
            ),
          ),
          child: Text(
            value?.isNotEmpty == true ? value! : hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: value?.isNotEmpty == true ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sectionTitle != null) ...[
            Text(
              widget.sectionTitle!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Đang tải danh sách địa chỉ...'),
              ],
            ),
          ),
        ],
      );
    }

    if (_loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sectionTitle != null) ...[
            Text(
              widget.sectionTitle!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
          ],
          Text(_loadError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
        ],
      );
    }

    final showWard = widget.mode == VietnamAddressPickerMode.full;
    final provinceItems = _provinces.map((p) => (code: p.code, name: p.name)).toList();
    final districtItems = _districts.map((d) => (code: d.code, name: d.name)).toList();
    final wardItems = _wards.map((w) => (code: w.code, name: w.name)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sectionTitle != null) ...[
          Text(
            widget.sectionTitle!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
        _selectField(
          label: widget.provinceRequired ? '${widget.provinceLabel} *' : widget.provinceLabel,
          value: _selection.provinceName,
          hint: 'Chọn tỉnh/thành',
          enabled: true,
          onTap: () async {
            final code = await _openPickerSheet(
              title: widget.provinceLabel,
              items: provinceItems,
              selectedCode: _selection.provinceCode,
            );
            if (code != null) _onProvinceChanged(code);
          },
        ),
        SizedBox(height: widget.spacing),
        _selectField(
          label: widget.districtOptional
              ? '${widget.districtLabel} (tuỳ chọn)'
              : '${widget.districtLabel} *',
          value: _selection.districtName,
          hint: _selection.provinceCode == null ? 'Chọn tỉnh trước' : 'Chọn quận/huyện',
          enabled: _selection.provinceCode != null,
          onTap: _selection.provinceCode == null
              ? null
              : () async {
                  final code = await _openPickerSheet(
                    title: widget.districtLabel,
                    items: districtItems,
                    selectedCode: _selection.districtCode,
                  );
                  if (code != null) _onDistrictChanged(code);
                },
        ),
        if (showWard) ...[
          SizedBox(height: widget.spacing),
          _selectField(
            label: '${widget.wardLabel} *',
            value: _selection.wardName,
            hint: _selection.districtCode == null ? 'Chọn quận trước' : 'Chọn phường/xã',
            enabled: _selection.districtCode != null,
            onTap: _selection.districtCode == null
                ? null
                : () async {
                    final code = await _openPickerSheet(
                      title: widget.wardLabel,
                      items: wardItems,
                      selectedCode: _selection.wardCode,
                    );
                    if (code != null) _onWardChanged(code);
                  },
          ),
        ],
        if (showWard && widget.showStreetDetail) ...[
          SizedBox(height: widget.spacing),
          TextField(
            controller: _streetCtrl,
            onChanged: (_) => _emit(),
            decoration: _fieldDecoration(
              widget.streetLabel,
              hint: widget.streetHint,
            ).copyWith(suffixIcon: widget.streetSuffixIcon),
          ),
        ],
      ],
    );
  }
}
