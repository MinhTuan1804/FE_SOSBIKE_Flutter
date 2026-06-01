import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

class MechanicFlowTitleBar extends StatelessWidget {
  const MechanicFlowTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.onGoHome,
    this.includeTopSafeArea = false,
  });

  final String title;
  final Widget? leading;
  final VoidCallback? onGoHome;
  final bool includeTopSafeArea;

  @override
  Widget build(BuildContext context) {
    final top = includeTopSafeArea ? MediaQuery.paddingOf(context).top : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 10, left: 12, right: 12, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onGoHome != null)
            IconButton(
              onPressed: onGoHome,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              tooltip: 'Về trang chủ',
            )
          else if (leading != null)
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
