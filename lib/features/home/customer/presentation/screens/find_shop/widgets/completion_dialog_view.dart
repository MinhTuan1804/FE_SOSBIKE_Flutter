import 'package:flutter/material.dart';

class CompletionDialogView extends StatelessWidget {
  const CompletionDialogView({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred/darkened map background
          Positioned.fill(
            child: Container(
              color: Colors.grey[900],
              child: Image.asset(
                'assets/images/main/map_card.png',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.map_rounded, color: Colors.white24, size: 100),
                ),
              ),
            ),
          ),

          // Modal dialog card in the center
          Center(
            child: Container(
              width: 320,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 15, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handlebar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  const Text(
                    'Đã đến nơi!',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Cảm ơn bạn đã sử dụng dịch vụ\nChúc bạn có một chuyến đi suôn sẻ!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5 Star Rating
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // "Đánh giá" secondary button
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6), // soft blue background
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      minimumSize: const Size(100, 32),
                    ),
                    child: const Text(
                      'Đánh giá',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "Hoàn Thành" primary button
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 28),
                    child: ElevatedButton(
                      onPressed: onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC02020),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Hoàn Thành',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
