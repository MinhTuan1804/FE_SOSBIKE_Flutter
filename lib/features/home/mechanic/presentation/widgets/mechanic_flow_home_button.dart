import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Nút quay về trang chủ khi đang trong flow đơn (fullscreen).
class MechanicFlowHomeButton extends StatelessWidget {
  const MechanicFlowHomeButton({
    super.key,
    required this.onGoHome,
    this.compact = false,
  });

  final VoidCallback onGoHome;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onGoHome,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.home_rounded, size: 18, color: AppColors.primary),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onGoHome,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Về trang chủ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay góc trên phải — dùng trên màn map fullscreen.
class MechanicFlowHomeOverlay extends StatelessWidget {
  const MechanicFlowHomeOverlay({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 8,
      right: 8,
      child: MechanicFlowHomeButton(onGoHome: onGoHome),
    );
  }
}

/// Tỷ lệ chiều cao bottom sheet — nhỏ hơn để map/nội dung rộng hơn.
const kMechanicFlowSheetRatio = 0.38;
