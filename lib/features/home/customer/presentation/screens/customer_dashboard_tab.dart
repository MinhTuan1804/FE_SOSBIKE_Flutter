import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/config/app_config_provider.dart';
import 'package:fe_moblie_flutter/core/widgets/page_loader.dart';
import 'package:fe_moblie_flutter/features/home/data/models/blog_post_model.dart';
import 'package:fe_moblie_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/providers/vehicle_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_mechanic/find_mechanic_flow_page.dart';
import 'package:fe_moblie_flutter/features/danger_warning/presentation/screens/danger_warning_screen.dart';
import 'package:fe_moblie_flutter/features/share_route/presentation/screens/share_route_screen.dart';
import 'package:fe_moblie_flutter/features/booking/presentation/screens/booking_screen.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_shop/find_shop_flow_page.dart';

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
                _BlogSection(
                  isLoading: homeProvider.isLoading,
                  posts: homeProvider.posts,
                ),
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PageLoader(child: DangerWarningScreen()),
                            ),
                          );
                        },
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PageLoader(child: ShareRouteScreen()),
                            ),
                          );
                        },
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

                        // Đặt lịch button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PageLoader(child: BookingScreen()),
                              ),
                            );
                          },
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

          // Card 2: Tìm Tiệm
          _buildSelectionCard(
            assetPath: 'assets/images/found_mechanic/tim_tiem.png',
            title: 'Tìm Tiệm',
            buttonText: 'Đi Ngay',
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const PageLoader(child: FindShopFlowPage()),
                ),
              ).then((_) {
                // Return to dashboard when exiting the flow
                setState(() {
                  _showFindMechanicSelection = false;
                });
              });
            },
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

class _BlogSection extends StatelessWidget {
  final bool isLoading;
  final List<BlogPostModel> posts;

  const _BlogSection({
    required this.isLoading,
    required this.posts,
  });

  void _showAllBlogsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tất cả bài viết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C1111),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (itemContext, index) {
                    final post = posts[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (context.mounted) {
                            _BlogCard(post: post).showBlogDetailModal(context);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8DADA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 100,
                                  height: 80,
                                  child: Image.network(
                                    post.coverImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFEEE3E3),
                                      child: const Icon(Icons.article, size: 28, color: Color(0xFF8B1A1A)),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 100,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEE3E3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.article, size: 28, color: Color(0xFF8B1A1A)),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.category != null && post.category!.isNotEmpty) ...[
                                    Text(
                                      post.category!.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    post.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C1111),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DADA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Blog mới từ SOSBIKE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C1111)),
              ),
              if (posts.length > 5)
                TextButton(
                  onPressed: () => _showAllBlogsModal(context),
                  child: const Text(
                    'Xem thêm',
                    style: TextStyle(color: Color(0xFF8B1A1A), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tin tức, mẹo bảo dưỡng và hướng dẫn an toàn cho người đi xe máy.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (posts.isEmpty)
            Text('Chưa có bài viết nào.', style: TextStyle(fontSize: 13, color: Colors.grey[700]))
          else
            SizedBox(
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length > 5 ? 5 : posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _BlogCard(post: post);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogPostModel post;

  const _BlogCard({required this.post});

  void showBlogDetailModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              // Close Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chi tiết bài viết',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              post.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFEEE3E3),
                                child: const Icon(Icons.article, size: 48, color: Color(0xFF8B1A1A)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (post.category != null && post.category!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1A1A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.category!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B1A1A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C1111),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (post.publishedAt != null) ...[
                        Text(
                          'Đăng ngày: ${post.publishedAt!.day.toString().padLeft(2, '0')}/${post.publishedAt!.month.toString().padLeft(2, '0')}/${post.publishedAt!.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 16),
                      Text(
                        post.content != null && post.content!.trim().isNotEmpty
                            ? post.content!
                            : post.summary,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
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
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: () => showBlogDetailModal(context),
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty
                      ? Image.network(
                          post.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEEE3E3),
                            child: const Icon(Icons.article, size: 42, color: Color(0xFF8B1A1A)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFEEE3E3),
                          child: const Icon(Icons.article, size: 42, color: Color(0xFF8B1A1A)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.category != null && post.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1A1A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.category!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8B1A1A)),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2C1111)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
