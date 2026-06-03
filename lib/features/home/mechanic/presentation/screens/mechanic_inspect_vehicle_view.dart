import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_session_spare_part.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';

/// **Kiểm tra xe + báo giá** — dịch vụ và phụ tùng trên cùng một màn.
class MechanicInspectVehicleView extends StatefulWidget {
  const MechanicInspectVehicleView({
    super.key,
    required this.onBack,
    required this.onComplete,
    required this.onGoHome,
    this.onStartRepair,
    required this.spareParts,
    required this.catalogSpareParts,
    required this.onAddSparePart,
    required this.onRemoveSparePart,
    this.initialItems = MechanicRepairLineItem.sampleServices,
    this.preselectedItems = const [],
    this.isLoadingServices = false,
    this.isLoadingCatalog = false,
    this.isSubmitting = false,
    this.quoteSent = false,
  });

  final VoidCallback onBack;
  final VoidCallback onGoHome;
  final Future<void> Function(List<MechanicRepairLineItem> selected) onComplete;
  final Future<void> Function()? onStartRepair;
  final List<MechanicSessionSparePart> spareParts;
  final List<MechanicSparePartDto> catalogSpareParts;
  final ValueChanged<MechanicSessionSparePart> onAddSparePart;
  final ValueChanged<String> onRemoveSparePart;
  final List<MechanicRepairLineItem> initialItems;
  final List<MechanicRepairLineItem> preselectedItems;
  final bool isLoadingServices;
  final bool isLoadingCatalog;
  final bool isSubmitting;
  final bool quoteSent;

  @override
  State<MechanicInspectVehicleView> createState() => _MechanicInspectVehicleViewState();
}

class _MechanicInspectVehicleViewState extends State<MechanicInspectVehicleView> {
  late List<MechanicRepairLineItem> _items;
  final _partNameCtrl = TextEditingController();
  final _partPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final preselectedIds = widget.preselectedItems.map((e) => e.id).toSet();
    if (preselectedIds.isNotEmpty) {
      _items = widget.initialItems
          .map((item) => item.copyWith(selected: preselectedIds.contains(item.id)))
          .toList();
    } else {
      _items = widget.initialItems
          .map((item) => item.id == '1' ? item.copyWith(selected: true) : item)
          .toList();
    }
  }

  @override
  void didUpdateWidget(covariant MechanicInspectVehicleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems) {
      final preselectedIds = widget.preselectedItems.map((e) => e.id).toSet();
      if (preselectedIds.isNotEmpty) {
        _items = widget.initialItems
            .map((item) => item.copyWith(selected: preselectedIds.contains(item.id)))
            .toList();
      } else {
        _items = widget.initialItems
            .map((item) => item.id == '1' ? item.copyWith(selected: true) : item)
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _partNameCtrl.dispose();
    _partPriceCtrl.dispose();
    super.dispose();
  }

  int get _serviceTotal => _items.where((e) => e.selected).fold(0, (s, e) => s + e.laborFee);
  int get _partsTotal => widget.spareParts.fold(0, (s, p) => s + p.price);
  int get _grandTotal => _serviceTotal + _partsTotal;

  static String _formatVnd(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  void _toggle(String id) {
    setState(() {
      _items = _items
          .map((item) => item.id == id ? item.copyWith(selected: !item.selected) : item)
          .toList();
    });
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
    setState(() {});
  }

  void _addCatalogPart(MechanicSparePartDto part) {
    if (widget.spareParts.any((p) => p.catalogPartId == part.partId)) return;
    widget.onAddSparePart(
      MechanicSessionSparePart.fromCatalog(
        partId: part.partId,
        name: part.name,
        price: part.price,
      ),
    );
    setState(() {});
  }

  Future<void> _handleSubmitQuote() async {
    final selected = _items.where((e) => e.selected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất một dịch vụ sửa chữa')),
      );
      return;
    }
    await widget.onComplete(selected);
  }

  Future<void> _handleStartRepair() async {
    if (widget.onStartRepair != null) {
      await widget.onStartRepair!();
    }
  }

  @override
  Widget build(BuildContext context) {
    const stepIndex = 1;
    final showStartRepair = widget.quoteSent && widget.onStartRepair != null;
    final showWaiting = widget.quoteSent && widget.onStartRepair == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MechanicFlowTitleBar(
              title: 'Kiểm tra xe',
              includeTopSafeArea: true,
              onGoHome: widget.onGoHome,
              leading: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFFFF5F5),
                child: widget.isLoadingServices && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        children: [
                          _SectionTitle('Dịch vụ sửa chữa', trailing: _formatVnd(_serviceTotal)),
                          const SizedBox(height: 8),
                          ..._items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RepairLineTile(item: item, onTap: () => _toggle(item.id)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionTitle('Báo giá phụ tùng', trailing: _formatVnd(_partsTotal)),
                          const SizedBox(height: 8),
                          if (widget.isLoadingCatalog)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                          else ...[
                            ...widget.catalogSpareParts.map((part) {
                              final selected = widget.spareParts.any((p) => p.catalogPartId == part.partId);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Material(
                                  color: selected ? const Color(0xFFDBEAFE) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: selected ? null : () => _addCatalogPart(part),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                            color: const Color(0xFF2563EB),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(part.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          ),
                                          Text(_formatVnd(part.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF2563EB))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _partNameCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Tên phụ tùng',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _partPriceCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: 'Giá (VND)',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: _submitSparePart,
                                      borderRadius: BorderRadius.circular(12),
                                      child: const SizedBox(
                                        height: 42,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 6),
                                            Text('Thêm phụ tùng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (widget.spareParts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...widget.spareParts.map(
                              (part) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _PartChip(
                                  label: part.name,
                                  price: _formatVnd(part.price),
                                  onRemove: () {
                                    widget.onRemoveSparePart(part.id);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                const Spacer(),
                                Text(_formatVnd(_grandTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF16A34A))),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MechanicOrderStepper(activeIndex: stepIndex),
                  if (showWaiting) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Chờ khách xác nhận báo giá',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Material(
                    color: widget.isSubmitting || showWaiting
                        ? const Color(0xFF9CA3AF)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: widget.isSubmitting || showWaiting
                          ? null
                          : (showStartRepair ? _handleStartRepair : _handleSubmitQuote),
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 46,
                        width: double.infinity,
                        child: Center(
                          child: widget.isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  showWaiting
                                      ? 'Chờ khách xác nhận'
                                      : showStartRepair
                                          ? 'Bắt đầu sửa · ${_formatVnd(_grandTotal)}'
                                          : 'Gửi báo giá · ${_formatVnd(_grandTotal)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827))),
        const Spacer(),
        Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF374151))),
      ],
    );
  }
}

class _PartChip extends StatelessWidget {
  const _PartChip({required this.label, required this.price, required this.onRemove});
  final String label;
  final String price;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF2563EB))),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28)),
        ],
      ),
    );
  }
}

class _RepairLineTile extends StatelessWidget {
  const _RepairLineTile({required this.item, required this.onTap});
  final MechanicRepairLineItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = item.selected;
    return Material(
      color: selected ? const Color(0xFFE8F5E9) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: selected ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? const Color(0xFF166534) : const Color(0xFF374151))),
                    Text('Phí dịch vụ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(item.priceLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: selected ? const Color(0xFF16A34A) : const Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}
