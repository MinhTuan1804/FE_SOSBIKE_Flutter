import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/providers/vehicle_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerDashboardTab extends StatefulWidget {
  const CustomerDashboardTab({super.key});

  @override
  State<CustomerDashboardTab> createState() => _CustomerDashboardTabState();
}

class _CustomerDashboardTabState extends State<CustomerDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchMyVehicles();
    });
  }

  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // White background section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                const _SosBanner(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        customIcon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBF2121), width: 2),
                          ),
                          child: Icon(Icons.error, color: Colors.red[400], size: 28),
                        ),
                        title: 'Cảnh báo nguy hiểm',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        customIcon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBF2121), width: 2),
                          ),
                          child: Icon(Icons.location_on, color: Colors.red[400], size: 28),
                        ),
                        title: 'Chia sẻ lộ trình',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Maintenance section with custom V-shape bottom
          ClipPath(
            clipper: _MaintenanceClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3b1818), Color(0xFF1c0a0a)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Motorcycle Image
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child:
                         Image.asset(
                              'assets/images/main/red_motorcycle.png',
                              height: 220,
                              fit: BoxFit.fitHeight,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.motorcycle,
                                size: 100,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(width: 4),
                  // Right side: Maintenance Info
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Sổ bảo dưỡng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.book, color: Colors.white.withValues(alpha: 0.8), size: 18),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _MaintenanceItem(
                          icon: Icons.water_drop,
                          iconColor: Colors.red,
                          title: 'Dầu động cơ',
                          subtitle: 'Kỳ thay: 200km',
                          percentage: 0,
                          progressColor: Colors.red,
                        ),
                        const SizedBox(height: 12),

                        _MaintenanceItem(
                          icon: Icons.adjust,
                          iconColor: Colors.green,
                          title: 'Má phanh',
                          subtitle: 'Cần thay thế sau mỗi 1000km',
                          percentage: 89,
                          progressColor: Colors.green,
                        ),
                        const SizedBox(height: 12),

                        _MaintenanceItem(
                          icon: Icons.tire_repair,
                          iconColor: Colors.green,
                          title: 'Lốp xe',
                          subtitle: 'Tình trạng tốt',
                          percentage: 74,
                          progressColor: Colors.green,
                        ),
                        const SizedBox(height: 10),

                        // Đặt lịch button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1A1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Colors.white),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            minimumSize: const Size(100, 36),
                          ),
                          child: const Text(
                            'Đặt lịch',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom white space to avoid nav bar overlap
          Container(
            height: 80,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SosBanner extends StatelessWidget {
  const _SosBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/main/garage_bg.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.grey[800],
      ),
      child: Stack(
        children: [
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Motorcycle Icon top-left
          Positioned(
            top: 16,
            left: 16,
            child: Icon(Icons.two_wheeler, color: Colors.white.withValues(alpha: 0.9), size: 32),
          ),

          // SOS Text top-right
          const Positioned(
            top: 12,
            right: 20,
            child: Text(
              'SOS Ngay!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 2)),
                ],
              ),
            ),
          ),

          // Start Button bottom-right
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.start, color: Colors.white, size: 20),
              label: const Text(
                'Bắt đầu',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB02A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.white54, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    this.icon,
    this.customIcon,
    required this.title,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF6B1919),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ?? Icon(icon, color: Colors.red[400], size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceItem extends StatelessWidget {
  const _MaintenanceItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int percentage;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon Box
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: iconColor.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),

        // Texts & Progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage / 100.0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaintenanceClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
