import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_dashboard_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_dashboard_provider.dart';

/// Tab Đơn hàng — dashboard theo Figma, dữ liệu từ API.
class MechanicDashboardTab extends StatefulWidget {
  const MechanicDashboardTab({super.key});

  @override
  State<MechanicDashboardTab> createState() => _MechanicDashboardTabState();
}

class _MechanicDashboardTabState extends State<MechanicDashboardTab> {
  static final _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  static final _dateFormat = DateFormat('dd/MM HH:mm', 'vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicDashboardProvider>().load();
    });
  }

  String _formatCurrency(double amount) => '${_currencyFormat.format(amount)}đ';

  String _formatRating(double rating) => rating.toStringAsFixed(1);

  String _formatOrderCount(int count) => count.toString().padLeft(2, '0');

  void _showTripsSheet(List<MechanicTripSummary> trips) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (trips.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Chưa có chuyến đi nào.',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Chuyến đi gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        trip.requestAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${trip.status} · ${_dateFormat.format(trip.createdAt.toLocal())}'),
                      trailing: Text(
                        _formatCurrency(trip.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicDashboardProvider>();
    final dashboard = provider.dashboard;

    if (provider.isLoading && dashboard == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.errorMessage != null && dashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Không tải được dashboard.',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.refresh(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final data = dashboard ?? MechanicDashboardData.empty;
    final trips = data.recentTrips;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MapCard(onViewTrips: () => _showTripsSheet(trips)),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _RevenueCard(amount: _formatCurrency(data.todayRevenue))),
                      const SizedBox(width: 10),
                      Expanded(child: _RatingCard(rating: _formatRating(data.todayRating))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _OrdersCard(count: _formatOrderCount(data.todayOrderCount)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.onViewTrips});

  final VoidCallback onViewTrips;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/main/map_card.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE8EAED),
                child: const Center(
                  child: Icon(Icons.map_outlined, size: 48, color: AppColors.dotInactive),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(22),
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewTrips,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE83838), Color(0xFFC02020)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Xem chuyến đi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/main/stat_revenue_icon.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/main/stat_revenue_chart.png',
                width: 18,
                height: 18,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Doanh thu hôm nay',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF16A34A),
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    final ratingValue = double.tryParse(rating) ?? 0;
    final progress = (ratingValue / 5).clamp(0.0, 1.0);

    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/main/stat_rating_icon.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.star_border, color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const Text(
            'Đánh giá hôm nay',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: AppColors.primary,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$rating★',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEAB308),
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Số đơn hàng hôm nay',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/main/stat_orders_icon.png',
                width: 28,
                height: 28,
                color: AppColors.primary.withValues(alpha: 0.75),
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.list_alt,
                  color: AppColors.primary.withValues(alpha: 0.75),
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
