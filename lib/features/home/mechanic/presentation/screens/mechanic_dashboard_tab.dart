import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_dashboard_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_dashboard_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_setup_profile_screen.dart';


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

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Đang chờ';
      case 'ACCEPTED':
        return 'Đã nhận';
      case 'ARRIVED':
        return 'Đã đến';
      case 'QUOTING':
        return 'Báo giá';
      case 'REPAIRING':
        return 'Đang sửa';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'PAID':
        return 'Đã thanh toán';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

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
                      subtitle: Text('${_translateStatus(trip.status)} · ${_dateFormat.format(trip.createdAt.toLocal())}'),
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
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
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
    final auth = context.watch<AuthProvider>();
    final isVerified = auth.profile?.mechanic?.isVerified ?? false;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Banner hoàn thiện hồ sơ (hiển thị nếu chưa được duyệt) ──
                if (!isVerified) ...[
                  _SetupProfileBanner(),
                  const SizedBox(height: 4),
                ],
                _MapCard(onViewTrips: () => _showTripsSheet(data.recentTrips)),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _RevenueCard(
                          amount: _formatCurrency(data.todayRevenue),
                          cashAmount: _formatCurrency(data.todayRevenueCash),
                          qrAmount: _formatCurrency(data.todayRevenueQr),
                          transferAmount: _formatCurrency(data.todayRevenueTransfer),
                        ),
                      ),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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

class _DashboardStyles {
  static const label = TextStyle(
    fontSize: 15,
    color: Color(0xFF111827),
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.amount,
    required this.cashAmount,
    required this.qrAmount,
    required this.transferAmount,
  });

  final String amount;
  final String cashAmount;
  final String qrAmount;
  final String transferAmount;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Doanh thu hôm nay',
            style: _DashboardStyles.label,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF16A34A),
                height: 1.05,
              ),
            ),
          ),
          const Divider(height: 12, thickness: 1),
          _breakdownRow('QR PayOS', qrAmount, const Color(0xFF2563EB)),
          const SizedBox(height: 4),
          _breakdownRow('Tiền mặt', cashAmount, const Color(0xFF16A34A)),
          const SizedBox(height: 4),
          _breakdownRow('Chuyển khoản', transferAmount, const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
        ),
      ],
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
      minHeight: 132,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEAB308),
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đánh giá hôm nay',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _DashboardStyles.label,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 72, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Số đơn hàng hôm nay',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _DashboardStyles.label,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/main/stat_orders_icon.png',
                  width: 30,
                  height: 30,
                  color: AppColors.primary.withValues(alpha: 0.75),
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.list_alt,
                    color: AppColors.primary.withValues(alpha: 0.75),
                    size: 30,
                  ),
                ),
              ],
            ),
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
    this.minHeight,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Banner hoàn thiện hồ sơ ───────────────────────────────────────────────────

class _SetupProfileBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: ẩn banner sau khi admin đã duyệt (kiểm tra status từ AuthProvider)
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => const MechanicSetupProfileScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.92),
              AppColors.primary.withValues(alpha: 0.75),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_ind_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoàn thiện hồ sơ thợ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Thêm chuyên môn, khu vực & ảnh để được duyệt nhanh hơn',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}
