import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

class RouteDirectionsView extends StatelessWidget {
  const RouteDirectionsView({
    super.key,
    required this.onBack,
    required this.onArrive,
  });

  final VoidCallback onBack;
  final VoidCallback onArrive;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Night-mode navigation map background
          Positioned.fill(
            child: GestureDetector(
              onTap: onArrive, // Tap map to simulate arrival
              child: Image.asset(
                'assets/images/main/map_card.png',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.35),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.map_rounded, color: Colors.white24, size: 100),
                ),
              ),
            ),
          ),

          // Header with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: topPadding + 8, bottom: 16, left: 16, right: 16),
              color: AppColors.primary,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Navigation Instructions Overlay (Top Left)
          Positioned(
            top: topPadding + 64,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đi về hướng',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'ĐÔNG NAM',
                        style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sound Toggle Button (Top Right)
          Positioned(
            top: topPadding + 64,
            right: 16,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.red, size: 24),
            ),
          ),

          // Map Zoom Controls (Bottom Right, above panel)
          Positioned(
            bottom: screenHeight * 0.28,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black54),
                    onPressed: () {},
                  ),
                  Container(width: 20, height: 1, color: Colors.grey[200]),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.black54),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Developer simulator hint label
          Positioned(
            bottom: screenHeight * 0.26,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '💡 Nhấn vào bản đồ hoặc bảng điều hướng để giả lập Đã Đến Nơi',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // Navigation Information Sheet (Bottom Panel)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * 0.23,
            child: GestureDetector(
              onTap: onArrive, // Tap panel to simulate arrival
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info text
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Còn 2 Phút',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '500 m. Dự kiến đến lúc 16:32',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // "Trở về" Action button
                    ElevatedButton(
                      onPressed: onBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC02020),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      child: const Text(
                        'Trở về',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
