import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/widgets/app_network_image.dart';

/// Header đỏ full width; vùng Trực tuyến kéo sát mép phải (Figma).
class MainAppHeader extends StatelessWidget {
  const MainAppHeader({
    super.key,
    required this.userName,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.userType,
    this.avatarUrl,
    this.onAvatarTap,
    this.onLocationTap,
  });

  final String userName;
  final bool isOnline;
  final ValueChanged<bool> onOnlineChanged;
  final String? userType;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;

  static const _mechanicStripWidth = 100.0;
  static const _rowMinHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final isCustomer = userType?.toUpperCase() == 'CUSTOMER';
    final stripW = isCustomer ? 48.0 : _mechanicStripWidth;

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
            padding: EdgeInsets.only(right: stripW - 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowMinHeight),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                const SizedBox(width: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAvatarTap,
                  child: Container(
                    width: 50,
                    height: 50,
                    child: ClipOval(
                      child: _buildAvatarImage(),
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
            width: stripW,
            child: Center(
              child: isCustomer
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _LocationButton(onTap: onLocationTap),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _MechanicOnlineStrip(
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

  Widget _buildAvatarImage() {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return Image.asset(
        'assets/images/main/avatar_placeholder.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person,
          color: AppColors.primary,
          size: 30,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Image.asset(
        'assets/images/main/avatar_placeholder.png',
        fit: BoxFit.cover,
      ),
      errorWidget: (_, __, ___) => Image.asset(
        'assets/images/main/avatar_placeholder.png',
        fit: BoxFit.cover,
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

/// Strip mép phải header thợ: nhãn + toggle (Figma).
class _MechanicOnlineStrip extends StatelessWidget {
  const _MechanicOnlineStrip({
    required this.isOnline,
    required this.onChanged,
  });

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(26)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.95),
            const Color(0xFF6B1010),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(-3, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? const Color(0xFF7CFC9A)
                      : Colors.white.withValues(alpha: 0.35),
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7CFC9A).withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Trực tuyến',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _OnlineToggle(value: isOnline, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _trackW = 60.0;
  static const _trackH = 24.0;
  static const _thumbSize = 18.0;
  static const _pad = 3.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value ? 'Đang trực tuyến' : 'Đang ngoại tuyến',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _trackW,
          height: _trackH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_trackH / 2),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: value
                  ? [
                      const Color(0xFFFF6B6B),
                      AppColors.primary,
                    ]
                  : [
                      const Color(0xFF5C0D0D),
                      const Color(0xFF3D0808),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              if (value)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(_pad),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment:
                        value ? Alignment.centerLeft : Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: value ? 10 : 6,
                        right: value ? 6 : 10,
                      ),
                      child: Text(
                        value ? 'on' : 'off',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1,
                          letterSpacing: 0.5,
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
    );
  }
}
