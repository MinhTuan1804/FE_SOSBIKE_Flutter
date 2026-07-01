import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/models/customer_order_history_entry.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/customer_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/customer_review_mechanic_screen.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/find_mechanic_flow_page.dart';

class CustomerOrderHistoryTab extends StatefulWidget {
  const CustomerOrderHistoryTab({super.key});

  @override
  State<CustomerOrderHistoryTab> createState() => _CustomerOrderHistoryTabState();
}

class _CustomerOrderHistoryTabState extends State<CustomerOrderHistoryTab> {
  static final _timeFormat = DateFormat('HH:mm - dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerHistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerHistoryProvider>();
    final rescue = context.watch<RescueProvider>();
    final items = provider.items;
    final activeOrderId = rescue.currentOrderId;
    final hasActive = activeOrderId != null && (rescue.activeOrderStatus?.toUpperCase() != 'COMPLETED');

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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  provider.refresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(120, 48),
                ),
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
                'Lịch sử đơn của tôi',
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
        if (hasActive) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FindMechanicFlowPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đơn đang xử lý (${rescue.activeOrderStatus ?? "..."})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.refresh,
            child: items.isEmpty && !hasActive
                ? Center(
                    child: Text(
                      'Chưa có lịch sử đơn nào.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _HistoryCard(
                      entry: items[index],
                      timeFormat: _timeFormat,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.timeFormat});

  final CustomerOrderHistoryEntry entry;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(avatarUrl: entry.avatarUrl),
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
                      entry.mechanicName,
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
                  if (entry.hasReview && entry.rating != null)
                    _StarRating(rating: entry.rating!)
                  else if (entry.canReview)
                    const _ReviewReadyBadge(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.vehicleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
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
                  ),
                ),
              ),
            ],
          ),
          if (entry.hasReview && entry.reviewComment != null && entry.reviewComment!.trim().isNotEmpty) ...[
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng tiền: ${entry.totalAmountLabel}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                ],
              ),
              _PaymentBadge(label: entry.paymentMethod),
            ],
          ),
          if (entry.canReview) ...[
            const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CustomerReviewMechanicScreen(
                          orderId: entry.id,
                          mechanicName: entry.mechanicName,
                          mechanicAvatarUrl: entry.avatarUrl,
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      await context.read<CustomerHistoryProvider>().refresh();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Đánh giá thợ', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ] else if (entry.hasReview) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFFFFD54F), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Đã đánh giá ${entry.rating ?? 0} sao',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    return ClipOval(
      child: Container(
        width: 42,
        height: 42,
        color: AppColors.primaryDark,
        child: url.isEmpty
            ? const Icon(Icons.person, color: Colors.white70)
            : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: 42, height: 42),
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
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFFE01B),
          size: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ReviewReadyBadge extends StatelessWidget {
  const _ReviewReadyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.35)),
      ),
      child: const Text(
        'Có thể đánh giá',
        style: TextStyle(color: Color(0xFFFFF59D), fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
