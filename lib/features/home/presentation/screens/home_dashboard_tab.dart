import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Tab Đơn hàng — dashboard theo Figma.
class HomeDashboardTab extends StatelessWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MapCard(),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _RevenueCard()),
              SizedBox(width: 12),
              Expanded(child: _RatingCard()),
            ],
          ),
          const SizedBox(height: 12),
          const _OrdersCard(),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
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
              right: 12,
              bottom: 12,
              child: Image.asset(
                'assets/images/main/btn_view_trips.png',
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Xem chuyến đi', style: TextStyle(fontWeight: FontWeight.w700)),
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
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/main/stat_revenue_icon.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(Icons.show_chart, color: AppColors.primary, size: 22),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/main/stat_revenue_chart.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Doanh thu hôm nay',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          const Text(
            '500.000đ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/main/stat_rating_icon.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(Icons.star_border, color: AppColors.primary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Đánh giá hôm nay',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Center(
            child: Image.asset(
              'assets/images/main/stat_rating_value.png',
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                '4.8',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số đơn hàng hôm nay',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '05',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/main/stat_orders_icon.png',
            width: 28,
            height: 28,
            color: const Color(0xFF9CA3AF),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => const Icon(Icons.list_alt, color: Color(0xFF9CA3AF), size: 28),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
