import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Header đỏ full width; vùng Trực tuyến kéo sát mép phải (Figma).
class MainAppHeader extends StatelessWidget {
  const MainAppHeader({
    super.key,
    required this.userName,
    required this.isOnline,
    required this.onOnlineChanged,
    this.onAvatarTap,
  });

  final String userName;
  final bool isOnline;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback? onAvatarTap;

  static const _statusStripWidth = 108.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 8, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(right: _statusStripWidth - 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/main/avatar_placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: _statusStripWidth,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
              ),
              child: Center(
                child: _OnlineStatusBlock(
                  isOnline: isOnline,
                  onChanged: onOnlineChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineStatusBlock extends StatelessWidget {
  const _OnlineStatusBlock({
    required this.isOnline,
    required this.onChanged,
  });

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Trực tuyến',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        _OnlineToggle(value: isOnline, onChanged: onChanged),
      ],
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _trackW = 58.0;
  static const _trackH = 26.0;
  static const _thumb = 22.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: _trackW,
        height: _trackH,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_trackH / 2),
              child: Image.asset(
                'assets/images/main/header_toggle_track.png',
                width: _trackW,
                height: _trackH,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_trackH / 2),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: value ? _trackW - _thumb - 2 : 2,
              top: (_trackH - _thumb) / 2,
              child: Container(
                width: _thumb,
                height: _thumb,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      value ? 'on' : 'off',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
