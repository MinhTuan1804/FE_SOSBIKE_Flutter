import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Header đỏ full width; vùng Trực tuyến kéo sát mép phải (Figma).
class MainAppHeader extends StatelessWidget {
  const MainAppHeader({
    super.key,
    required this.userName,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.userType,
    this.onAvatarTap,
    this.onLocationTap,
  });

  final String userName;
  final bool isOnline;
  final ValueChanged<bool> onOnlineChanged;
  final String? userType;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;

  static const _statusStripWidth = 112.0;
  /// Cao hơn avatar (50) để strip Trực tuyến không ép Column trong 42px.
  static const _rowMinHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final isCustomer = userType?.toUpperCase() == 'CUSTOMER';

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowMinHeight),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 50,
                    height: 50,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/main/avatar_placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xin chào!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
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
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: isCustomer ? -20 : 0,
            bottom: 0,
            width: _statusStripWidth,
            child: Center(
              child: Container(
                width: isCustomer ? 40 : 80,
                height: isCustomer ? 40 : 120,
                decoration: isCustomer
                    ? const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      )
                    : const BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          bottomLeft: Radius.circular(28),
                        ),
                      ),
                child: Center(
                  child: isCustomer
                      ? _LocationButton(onTap: onLocationTap)
                      : _OnlineStatusBlock(
                          isOnline: isOnline,
                          onChanged: onOnlineChanged,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () {},
      icon: const Icon(Icons.location_on_rounded),
      color: AppColors.primary,
      iconSize: 20,
      tooltip: 'Vị trí',
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Trực tuyến',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        _OnlineToggle(value: isOnline, onChanged: onChanged),
      ],
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _trackW = 72.0;
  static const _trackH = 26.0;
  static const _thumbSize = 14.0;
  static const _edgePad = 4.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: _trackW,
        height: _trackH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_trackH / 2),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_trackH / 2),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _edgePad),
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: value ? 10 : _thumbSize + _edgePad + 6,
                        right: value ? _thumbSize + _edgePad + 6 : 10,
                      ),
                      child: Align(
                        alignment: value
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
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
        ),
      ),
    );
  }
}
