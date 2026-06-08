import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/config/app_config_provider.dart';
import 'package:fe_moblie_flutter/core/widgets/page_loader.dart';
import 'package:fe_moblie_flutter/core/widgets/coming_soon_overlay.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/widgets/blog_section.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/providers/vehicle_provider.dart';
import 'package:fe_moblie_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/find_mechanic_flow_page.dart';

class CustomerDashboardTab extends StatefulWidget {
  const CustomerDashboardTab({super.key});

  @override
  State<CustomerDashboardTab> createState() => _CustomerDashboardTabState();
}

class _CustomerDashboardTabState extends State<CustomerDashboardTab> {
  bool _showFindMechanicSelection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().fetchPosts();
      context.read<VehicleProvider>().fetchMyVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigProvider>().config;
    final homeProvider = context.watch<HomeProvider>();
    if (_showFindMechanicSelection) {
      return _buildFindMechanicSelectionView();
    }

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
                _SosBanner(
                  brandName: appConfig.ui.brandName,
                  onStart: () {
                    setState(() {
                      _showFindMechanicSelection = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                BlogSection(
                  isLoading: homeProvider.isLoading,
                  posts: homeProvider.posts,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ComingSoonTapBlocker(
                        featureName: 'Cảnh báo nguy hiểm',
                        message:
                            'Tính năng cảnh báo cung đường nguy hiểm sẽ sớm được tích hợp.',
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ComingSoonTapBlocker(
                        featureName: 'Chia sẻ lộ trình',
                        message:
                            'Tính năng chia sẻ lộ trình với bạn bè sẽ sớm được ra mắt.',
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
                                fontSize: 20,
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

                        // Đặt lịch button — coming soon
                        ComingSoonTapBlocker(
                          featureName: 'Đặt lịch',
                          message: 'Tính năng đặt lịch bảo dưỡng định kỳ đang trong quá trình mở rộng.',
                          child: ElevatedButton(
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

  Widget _buildFindMechanicSelectionView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0202), Color(0xFF600808)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const SizedBox(height: 30),
          // Card 1: Tìm Thợ
          _buildSelectionCard(
            assetPath: 'assets/images/found_mechanic/tim_tho.png',
            title: 'Tìm Thợ',
            buttonText: 'Đặt ngay',
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const PageLoader(child: FindMechanicFlowPage()),
                ),
              ).then((_) {
                // Return to dashboard when exiting the flow
                setState(() {
                  _showFindMechanicSelection = false;
                });
              });
            },
          ),
          const SizedBox(height: 24),

          // Card 2: Tìm Tiệm — coming soon
          ComingSoonTapBlocker(
            featureName: 'Tìm Tiệm',
            message: 'Tính năng tìm tiệm sửa xe gần bạn đang trong quá trình mở rộng.',
            child: _buildSelectionCard(
              assetPath: 'assets/images/found_mechanic/tim_tiem.png',
              title: 'Tìm Tiệm',
              buttonText: 'Đi Ngay',
              onTap: () {},
            ),
          ),

          // Bottom padding to avoid nav bar overlap
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String assetPath,
    required String title,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.none,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.white, size: 60),
                  ),
                ),
              ),

              // Title text at top-left
              Positioned(
                top: 10,
                left: 20,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(2, 3),
                        blurRadius: 8,
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(-1, -1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // Button at bottom-right
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC02020), // Vibrant red matching Figma brand red/button
                    borderRadius: BorderRadius.circular(30), // fully rounded pill
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SosBanner extends StatelessWidget {
  const _SosBanner({required this.brandName, required this.onStart});
  final String brandName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
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
          Positioned(
            top: 12,
            right: 20,
            child: Text(
              brandName,
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
              onPressed: onStart,
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
    required this.customIcon,
    required this.title,
    required this.onTap,
  });

  final Widget customIcon;
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
            customIcon,
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
