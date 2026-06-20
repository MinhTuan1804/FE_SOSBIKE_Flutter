import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_service_offering_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_service_offering_provider.dart';

/// Tab **Dịch vụ** — thợ đăng ký dịch vụ riêng, chờ admin duyệt.
class MechanicServicesTab extends StatefulWidget {
  const MechanicServicesTab({super.key});

  @override
  State<MechanicServicesTab> createState() => _MechanicServicesTabState();
}

class _MechanicServicesTabState extends State<MechanicServicesTab> {
  static final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  static final _date = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicServiceOfferingProvider>().load(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicServiceOfferingProvider>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.load(force: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dịch vụ của tôi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng ký dịch vụ riêng. Sau khi admin duyệt, bạn có thể dùng trong báo giá sửa chữa.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: provider.isSubmitting ? null : () => _openCreateSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm dịch vụ mới'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (provider.isLoading && provider.items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (provider.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Chưa có dịch vụ nào.\nNhấn "Thêm dịch vụ mới" để đăng ký.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: provider.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ServiceCard(
                  item: provider.items[index],
                  money: _money,
                  date: _date,
                  onDelete: provider.isSubmitting
                      ? null
                      : () => _confirmDelete(context, provider.items[index].mechanicServiceId),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2332),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Đăng ký dịch vụ mới',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _field(
                  controller: nameCtrl,
                  label: 'Tên dịch vụ',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên dịch vụ' : null,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: feeCtrl,
                  label: 'Phí công (VNĐ)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Nhập phí công hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: descCtrl,
                  label: 'Mô tả (tùy chọn)',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(ctx, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Gửi duyệt'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok != true || !mounted) {
      nameCtrl.dispose();
      feeCtrl.dispose();
      descCtrl.dispose();
      return;
    }

    final provider = context.read<MechanicServiceOfferingProvider>();
    final success = await provider.create(
      serviceName: nameCtrl.text.trim(),
      laborFee: int.parse(feeCtrl.text.trim()),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );

    nameCtrl.dispose();
    feeCtrl.dispose();
    descCtrl.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã gửi yêu cầu duyệt dịch vụ.' : (provider.errorMessage ?? 'Gửi thất bại')),
        backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa dịch vụ?'),
        content: const Text('Chỉ xóa được dịch vụ đang chờ hoặc bị từ chối.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (yes != true || !mounted) return;

    final provider = context.read<MechanicServiceOfferingProvider>();
    final success = await provider.delete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã xóa dịch vụ.' : (provider.errorMessage ?? 'Xóa thất bại')),
        backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.item,
    required this.money,
    required this.date,
    this.onDelete,
  });

  final MechanicServiceOfferingDto item;
  final NumberFormat money;
  final DateFormat date;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (item.status) {
      'APPROVED' => ('Đã duyệt', const Color(0xFF43A047)),
      'REJECTED' => ('Từ chối', const Color(0xFFE53935)),
      _ => ('Chờ duyệt', const Color(0xFFFFB300)),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.serviceName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            money.format(item.laborFee),
            style: TextStyle(color: AppColors.primary.withValues(alpha: 0.95), fontWeight: FontWeight.w700),
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(
            'Gửi lúc ${date.format(item.requestedAt.toLocal())}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
          if (item.isRejected && item.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do: ${item.rejectionReason}',
              style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
            ),
          ],
          if (!item.isApproved && onDelete != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Xóa'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8A80)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
