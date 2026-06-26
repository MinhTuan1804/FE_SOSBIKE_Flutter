import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/widgets/coming_soon_overlay.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_app_header.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_bottom_nav_bar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0202), Color(0xFF5A0808)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Reusable App Header
            MainAppHeader(
              userName: auth.displayName,
              avatarUrl: auth.avatarUrl,
              isOnline: _isOnline,
              onOnlineChanged: (v) => setState(() => _isOnline = v),
              userType: auth.userType,
              onAvatarTap: () {},
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                children: [
                  // Vehicle Card
                  _buildVehicleCard(),
                  const SizedBox(height: 16),

                  // Maintenance items
                  _buildMaintenanceCard(
                    icon: Icons.water_drop_rounded,
                    iconBg: const Color(0xFF3b1818),
                    iconColor: Colors.redAccent,
                    title: 'Dầu Động Cơ',
                    subtitle: 'Trễ hạn 200km',
                    percentage: 0,
                    progressColor: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),

                  _buildMaintenanceCard(
                    icon: Icons.adjust_rounded,
                    iconBg: const Color(0xFF142e1b),
                    iconColor: Colors.greenAccent,
                    title: 'Má Phanh',
                    subtitle: 'Ước tính thời gian thay thế: 1.500km',
                    percentage: 45,
                    progressColor: Colors.greenAccent,
                  ),
                  const SizedBox(height: 12),

                  _buildMaintenanceCard(
                    icon: Icons.tire_repair_rounded,
                    iconBg: const Color(0xFF142e1b),
                    iconColor: Colors.greenAccent,
                    title: 'Lốp Xe',
                    subtitle: 'Tình trạng tốt!',
                    percentage: 60,
                    progressColor: Colors.greenAccent,
                  ),
                  const SizedBox(height: 24),

                  // Đặt lịch bảo dưỡng button — coming soon
                  ComingSoonTapBlocker(
                    featureName: 'Đặt lịch bảo dưỡng',
                    message: 'Tính năng đặt lịch bảo dưỡng định kỳ đang trong quá trình mở rộng.',
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Đặt lịch bảo dưỡng',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        elevation: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(
        current: MainNavTab.orders,
        onChanged: (_) {
          Navigator.of(context).pop();
        },
        userType: auth.userType,
        showActive: false,
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Scooter Image in white box
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/main/red_motorcycle.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.motorcycle_rounded,
                color: AppColors.primary,
                size: 50,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Vehicle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Honda Vision',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '29A1 - 123.45',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Dùng dịch vụ: 2 tháng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int percentage,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),

          // Progress & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100.0,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: percentage == 0 ? Colors.redAccent : Colors.white54,
                    fontSize: 11,
                    fontWeight: percentage == 0 ? FontWeight.bold : FontWeight.normal,
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
