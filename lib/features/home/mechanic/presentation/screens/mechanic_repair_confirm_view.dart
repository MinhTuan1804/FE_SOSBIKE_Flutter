import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';

/// **Xác nhận sửa xe** — hoàn tất hạng mục (Figma).
class MechanicRepairConfirmView extends StatelessWidget {
  const MechanicRepairConfirmView({
    super.key,
    required this.selectedItems,
    required this.onBack,
    required this.onAddMoreItems,
    required this.onCompleteRepair,
  });

  final List<MechanicRepairLineItem> selectedItems;
  final VoidCallback onBack;
  final VoidCallback onAddMoreItems;
  final VoidCallback onCompleteRepair;

  int get _totalPrice => selectedItems.fold(0, (sum, item) => sum + item.price);

  String get _totalPriceLabel {
    final formatted = _totalPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formatted VND';
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
              title: 'Xác nhận',
              leading: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF0FDF4),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hạng mục đã chọn',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                          Text(
                            _totalPriceLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onAddMoreItems,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                                  'Chọn thêm hạng mục',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: selectedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = selectedItems[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                                Text(
                                  item.priceLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          );
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
                title: 'Kiểm tra xe.',
                activeStep: 2,
                subtitle:
                    'Sau khi đã sửa xe thành công và chọn các khoản mục thanh toán, hãy nhấn nút "Hoàn thành".',
                action: Material(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onCompleteRepair,
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      height: 46,
                      child: Center(
                        child: Text(
                          'Hoàn thành sửa xe',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
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
