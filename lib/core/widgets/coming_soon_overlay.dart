import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Widget bọc ngoài màn hình / nút chưa có chức năng thật.
///
/// Dùng 2 cách:
///
/// 1. **Wrap toàn bộ màn hình** — hiển thị banner ở trên cùng:
/// ```dart
/// ComingSoonOverlay(
///   message: 'Đặt lịch bảo dưỡng đang trong quá trình mở rộng.',
///   child: BookingScreen(),
/// )
/// ```
///
/// 2. **Chặn một nút** — bắt tap và hiện dialog thay vì thực thi action:
/// ```dart
/// ComingSoonTapBlocker(
///   child: ElevatedButton(onPressed: () {}, child: Text('Gửi')),
/// )
/// ```
class ComingSoonOverlay extends StatelessWidget {
  const ComingSoonOverlay({
    super.key,
    required this.child,
    this.message,
    this.featureName,
    /// Chặn bấm UI phía dưới (chỉ xem preview + banner).
    this.blockInteraction = true,
  });

  final Widget child;
  final String? message;
  final String? featureName;
  final bool blockInteraction;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    // Chiều cao banner ≈ safe area + nội dung (khớp _ComingSoonBanner).
    final bannerBottom = topPad + 72.0;

    return Stack(
      children: [
        child,
        if (blockInteraction)
          Positioned(
            top: bannerBottom,
            left: 0,
            right: 0,
            bottom: 0,
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.02),
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ComingSoonBanner(
            message: message,
            featureName: featureName,
          ),
        ),
      ],
    );
  }
}

/// Banner thông báo "đang mở rộng" — hiển thị ở top của màn hình.
class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner({this.message, this.featureName});

  final String? message;
  final String? featureName;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 10, 14, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB91C1C), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featureName != null
                      ? '⏳ $featureName đang trong quá trình mở rộng'
                      : '⏳ Chức năng đang trong quá trình mở rộng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    message!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bọc quanh bất kỳ widget nào để chặn tap và hiện dialog "đang mở rộng".
class ComingSoonTapBlocker extends StatelessWidget {
  const ComingSoonTapBlocker({
    super.key,
    required this.child,
    this.featureName,
    this.message,
  });

  final Widget child;
  final String? featureName;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDialog(context),
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: child),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              featureName != null
                  ? '$featureName\nĐang trong quá trình mở rộng'
                  : 'Chức năng đang trong\nquá trình mở rộng',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Tính năng này sẽ sớm được ra mắt.\nVui lòng quay lại sau!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Đã hiểu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàm tiện ích — gọi dialog "đang mở rộng" từ bất kỳ đâu.
void showComingSoonDialog(
  BuildContext context, {
  String? featureName,
  String? message,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _ComingSoonDialog(
      featureName: featureName,
      message: message,
    ),
  );
}

class _ComingSoonDialog extends StatelessWidget {
  const _ComingSoonDialog({this.featureName, this.message});

  final String? featureName;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            featureName != null
                ? '$featureName\nĐang trong quá trình mở rộng'
                : 'Chức năng đang trong\nquá trình mở rộng',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                'Tính năng này sẽ sớm được ra mắt.\nVui lòng quay lại sau!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
