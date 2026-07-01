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
          Center(
            child: Container(
              width: 320,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFFC02020), size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'Đã đến nơi!',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thợ đã hoàn thành công việc và đơn của bạn đã sẵn sàng để tiếp tục các bước tiếp theo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
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
                      'Hoàn thành',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
