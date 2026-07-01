import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_customer_history_entry.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';

class MechanicCustomerHistoryTab extends StatefulWidget {
  const MechanicCustomerHistoryTab({super.key, this.onContinueOrder});

  final Future<void> Function()? onContinueOrder;

  @override
  State<MechanicCustomerHistoryTab> createState() => _MechanicCustomerHistoryTabState();
}

class _MechanicCustomerHistoryTabState extends State<MechanicCustomerHistoryTab> {
  static final _timeFormat = DateFormat('HH:mm - dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicHistoryProvider>().load();
      context.read<MechanicRepairProvider>().loadActiveOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicHistoryProvider>();
    final repairProvider = context.watch<MechanicRepairProvider>();
    final items = provider.items;
    final activeOrder = repairProvider.activeOrder;

    if (provider.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.errorMessage != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không tải được lịch sử.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: provider.refresh,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoạt động',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Lịch sử khách hàng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        if (activeOrder != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _InProgressOrderCard(
              customerName: activeOrder.customerName ?? 'Khách hàng',
              address: activeOrder.requestAddress,
              status: activeOrder.status,
              onContinue: widget.onContinueOrder,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.refresh,
            child: items.isEmpty && activeOrder == null
                ? Center(
                    child: Text(
                      'Chưa có lịch sử khách hàng.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(14, activeOrder != null ? 12 : 0, 14, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HistoryCard(
                        entry: items[index],
                        timeFormat: _timeFormat,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _InProgressOrderCard extends StatelessWidget {
  const _InProgressOrderCard({
    required this.customerName,
    required this.address,
    required this.status,
    this.onContinue,
  });

  final String customerName;
  final String address;
  final String status;
  final Future<void> Function()? onContinue;

  String get _statusLabel {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return 'Đang di chuyển';
      case 'ARRIVED':
      case 'QUOTING':
        return 'Đang kiểm tra xe';
      case 'REPAIRING':
        return 'Đang sửa xe';
      default:
        return 'Chưa hoàn thành';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ĐANG DỞ',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _statusLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onContinue == null ? null : () => onContinue!(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'Tiếp tục đơn',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.timeFormat});

  final MechanicCustomerHistoryEntry entry;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF9E1818).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CustomerAvatar(avatarUrl: entry.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeFormat.format(entry.completedAt.toLocal()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.hasReview && entry.rating != null) _StarRating(rating: entry.rating!),
                  const SizedBox(height: 6),
                  if (entry.hasReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Đã đánh giá',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6E1010),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.vehicleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (entry.reviewComment != null && entry.reviewComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                entry.reviewComment!.trim(),
                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Tổng tiền: ${entry.totalAmountLabel}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              _PaymentBadge(label: entry.paymentMethod),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
      ),
      child: ClipOval(
        child: url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            : Image.asset(
                'assets/images/main/avatar_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 24),
              ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: const Color(0xFFFFD54F),
        );
      }),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
