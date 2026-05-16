import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAsset,
    this.background = Colors.white,
    this.foreground = AppColors.textPrimary,
    this.border = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? iconAsset;
  final Color background;
  final Color foreground;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: border
              ? const BorderSide(color: AppColors.socialBorder)
              : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(icon, size: 22, color: foreground),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
