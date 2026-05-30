import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';

/// **Kiểm tra xe** — chọn hạng mục sửa (Figma).
class MechanicInspectVehicleView extends StatefulWidget {
  const MechanicInspectVehicleView({
    super.key,
    required this.onBack,
    required this.onStartRepair,
    this.initialItems = MechanicRepairLineItem.sampleServices,
    this.preselectedItems = const [],
    this.editingDuringRepair = false,
    this.isLoadingServices = false,
  });

  final VoidCallback onBack;
  final ValueChanged<List<MechanicRepairLineItem>> onStartRepair;
  final List<MechanicRepairLineItem> initialItems;
  /// Hạng mục đã chọn trước đó (khi quay lại từ bước sửa xe).
  final List<MechanicRepairLineItem> preselectedItems;
  /// true = thợ đang ở bước sửa xe, quay lại để bổ sung hạng mục.
  final bool editingDuringRepair;
  final bool isLoadingServices;

  @override
  State<MechanicInspectVehicleView> createState() => _MechanicInspectVehicleViewState();
}

class _MechanicInspectVehicleViewState extends State<MechanicInspectVehicleView> {
  late List<MechanicRepairLineItem> _items;
  final _noteController = TextEditingController();

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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      _items = _items
          .map((item) => item.id == id ? item.copyWith(selected: !item.selected) : item)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * 0.52;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MechanicFlowTitleBar(
              title: widget.editingDuringRepair ? 'Chọn thêm hạng mục' : 'Nhận Đơn',
              leading: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFFFF5F5),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Lốp xe',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: widget.isLoadingServices && _items.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        itemCount: _items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return TextField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Vấn đề khác...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          final item = _items[index];
                          return _RepairLineTile(item: item, onTap: () => _toggle(item.id));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sheetMaxH),
              child: MechanicOrderFlowSheetBody(
                title: widget.editingDuringRepair ? 'Bổ sung dịch vụ.' : 'Kiểm tra xe.',
                activeStep: widget.editingDuringRepair ? 2 : 1,
                subtitle: widget.editingDuringRepair
                    ? 'Chọn thêm dịch vụ sửa chữa. Phụ tùng sẽ nhập ở bước xác nhận.'
                    : 'Chọn dịch vụ sửa chữa (phí công). Phụ tùng nhập riêng sau khi bắt đầu sửa.',
                action: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => widget.onStartRepair(_items.where((e) => e.selected).toList()),
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 46,
                      child: Center(
                        child: Text(
                          widget.editingDuringRepair ? 'Cập nhật hạng mục' : 'Bắt đầu sửa → nhập phụ tùng',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
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
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected ? const Color(0xFF166534) : const Color(0xFF374151),
                      ),
                    ),
                    Text(
                      'Phí dịch vụ',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Text(
                item.priceLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: selected ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
