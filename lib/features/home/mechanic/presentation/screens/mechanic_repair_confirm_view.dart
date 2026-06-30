import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_session_spare_part.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_home_button.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';

/// **Sửa xe** — dịch vụ (app) + phụ tùng catalog + phụ tùng cộng thêm.
class MechanicRepairConfirmView extends StatefulWidget {
  const MechanicRepairConfirmView({
    super.key,
    required this.selectedServices,
    required this.spareParts,
    required this.catalogSpareParts,
    required this.onBack,
    required this.onGoHome,
    required this.onAddMoreServices,
    required this.onAddSparePart,
    required this.onRemoveSparePart,
    required this.onCompleteRepair,
    this.isSubmitting = false,
    this.isLoadingCatalog = false,
  });

  final List<MechanicRepairLineItem> selectedServices;
  final List<MechanicSessionSparePart> spareParts;
  final List<MechanicSparePartDto> catalogSpareParts;
  final VoidCallback onBack;
  final VoidCallback onGoHome;
  final VoidCallback onAddMoreServices;
  final ValueChanged<MechanicSessionSparePart> onAddSparePart;
  final ValueChanged<String> onRemoveSparePart;
  final Future<void> Function() onCompleteRepair;
  final bool isSubmitting;
  final bool isLoadingCatalog;

  @override
  State<MechanicRepairConfirmView> createState() => _MechanicRepairConfirmViewState();
}

class _MechanicRepairConfirmViewState extends State<MechanicRepairConfirmView> {
  final _partNameCtrl = TextEditingController();
  final _partPriceCtrl = TextEditingController();

  @override
  void dispose() {
    _partNameCtrl.dispose();
    _partPriceCtrl.dispose();
    super.dispose();
  }

  int get _serviceTotal => widget.selectedServices.fold(0, (sum, item) => sum + item.laborFee);
  int get _partsTotal => widget.spareParts.fold(0, (sum, part) => sum + part.price);
  int get _grandTotal => _serviceTotal + _partsTotal;

  static String _formatVnd(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  void _submitSparePart() {
    final name = _partNameCtrl.text.trim();
    final price = int.tryParse(_partPriceCtrl.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên phụ tùng và giá hợp lệ')),
      );
      return;
    }
    widget.onAddSparePart(
      MechanicSessionSparePart(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        price: price,
      ),
    );
    _partNameCtrl.clear();
    _partPriceCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _addCatalogPart(MechanicSparePartDto part) {
    if (widget.spareParts.any((p) => p.catalogPartId == part.partId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phụ tùng này đã có trong đơn')),
      );
      return;
    }
    widget.onAddSparePart(
      MechanicSessionSparePart.fromCatalog(
        partId: part.partId,
        name: part.name,
        price: part.price,
      ),
    );
  }

  bool _isCatalogPartSelected(String partId) =>
      widget.spareParts.any((p) => p.catalogPartId == partId);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * kMechanicFlowSheetRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MechanicFlowTitleBar(
              title: 'Xác nhận',
              includeTopSafeArea: true,
              onGoHome: widget.onGoHome,
              leading: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF0FDF4),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  children: [
                    _SummaryCard(
                      serviceTotal: _serviceTotal,
                      partsTotal: _partsTotal,
                      grandTotal: _grandTotal,
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Báo giá phụ tùng',
                      subtitle: 'Nhấn + để nhập tên và giá phụ tùng (sau khi khách xác minh)',
                      trailing: _formatVnd(_partsTotal),
                    ),
                    const SizedBox(height: 8),
                    if (widget.isLoadingCatalog)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (widget.catalogSpareParts.isNotEmpty) ...[
                      Text(
                        'Danh mục phụ tùng',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      ...widget.catalogSpareParts.map((part) {
                        final selected = _isCatalogPartSelected(part.partId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: selected ? const Color(0xFFDBEAFE) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: selected ? null : () => _addCatalogPart(part),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        part.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      _formatVnd(part.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Text(
                        'Phụ tùng cộng thêm (chỉ đơn này)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _partNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Tên phụ tùng *',
                              hintText: 'VD: Ruột xe 110/70-17, Lốp sau...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _partPriceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Giá phụ tùng (VND) *',
                              hintText: '150000',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _submitSparePart,
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                height: 48,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 6),
                                      Text(
                                        'Thêm phụ tùng vào đơn',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.spareParts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Chưa có phụ tùng. Không thay linh kiện thì bỏ qua, nhấn Hoàn thành.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      )
                    else
                      ...widget.spareParts.map(
                        (part) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LineTile(
                            label: part.isExtra ? '${part.name} (cộng thêm)' : part.name,
                            priceLabel: part.priceLabel,
                            accent: AppColors.primary,
                            onRemove: () => widget.onRemoveSparePart(part.id),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Dịch vụ sửa chữa',
                      subtitle: 'Phí công do app quy định',
                      trailing: _formatVnd(_serviceTotal),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: widget.onAddMoreServices,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Chọn thêm dịch vụ',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.selectedServices.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LineTile(label: item.label, priceLabel: item.priceLabel, accent: const Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sheetMaxH),
              child: MechanicOrderFlowSheetBody(
                title: 'Kiểm tra xe.',
                activeStep: 2,
                subtitle:
                    'Sau khi đã sửa xe thành công và chọn các khoản mục thanh toán, hãy nhấn nút Hoàn thành.',
                action: Material(
                  color: widget.isSubmitting ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: widget.isSubmitting ? null : () => widget.onCompleteRepair(),
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: widget.isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                'Hoàn thành sửa xe · ${_formatVnd(_grandTotal)}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.serviceTotal,
    required this.partsTotal,
    required this.grandTotal,
  });

  final int serviceTotal;
  final int partsTotal;
  final int grandTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        children: [
          _row('Dịch vụ sửa chữa', serviceTotal, const Color(0xFF16A34A)),
          const SizedBox(height: 6),
          _row('Phụ tùng', partsTotal, AppColors.primary),
          const Divider(height: 20),
          _row('Tổng cộng', grandTotal, const Color(0xFF111827), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, int amount, Color color, {bool bold = false}) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: bold ? 14 : 12,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Text(
          '$formattedđ',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: bold ? 15 : 13, color: color),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, required this.trailing});

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF166534))),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827))),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.label,
    required this.priceLabel,
    required this.accent,
    this.onRemove,
  });

  final String label;
  final String priceLabel;
  final Color accent;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(onRemove != null ? Icons.inventory_2_outlined : Icons.build_outlined, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: accent.withValues(alpha: 0.9))),
          ),
          Text(priceLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: accent)),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ],
      ),
    );
  }
}
