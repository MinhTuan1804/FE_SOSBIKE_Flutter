import 'package:flutter/material.dart';

class MainPlaceholderTab extends StatelessWidget {
  const MainPlaceholderTab({
    super.key,
    required this.title,
    this.iconAsset,
    this.icon,
  });

  final String title;
  final String? iconAsset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              )
            else
              Icon(
                icon ?? Icons.construction_outlined,
                size: 56,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nội dung sẽ được bổ sung sau.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
