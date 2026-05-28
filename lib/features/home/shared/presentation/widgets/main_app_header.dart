import 'package:cached_network_image/cached_network_image.dart';
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onAvatarTap,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE01B), // Gold/Yellow
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Color(0xFFC01515), // Red text
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
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
            right: isCustomer ? 10 : 8,
            bottom: 0,
            width: stripW,
            child: Center(
              child: isCustomer
                  ? Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        
                      ),
                      child: IconButton(onPressed: (){}, icon: Icon(Icons.location_on, color: AppColors.primary, size: 30)),
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

/// Strip mép phải header thợ: nhãn + toggle (Figma).
class _MechanicOnlineStrip extends StatelessWidget {
  const _MechanicOnlineStrip({
    required this.isOnline,
    required this.onChanged,
  });

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  static const _stripWidth = 84.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _stripWidth,
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC41E1E),
            Color(0xFF9A1515),
            Color(0xFF6E1010),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(-2, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? const Color(0xFF86F5A8)
                      : Colors.white.withValues(alpha: 0.42),
                  boxShadow: isOnline
                      ? [
                          BoxShadow(
                            color: const Color(0xFF86F5A8).withValues(alpha: 0.75),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Trực tuyến',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.98),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      height: 1.05,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          offset: const Offset(0, 0.5),
                          blurRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _OnlineToggle(value: isOnline, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _trackW = 58.0;
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
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: _trackW,
          height: _trackH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_trackH / 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: value
                  ? const [
                      Color(0xFFFF7A7A),
                      Color(0xFFE83838),
                      Color(0xFFC41E1E),
                    ]
                  : const [
                      Color(0xFF4A0A0A),
                      Color(0xFF2E0606),
                      Color(0xFF1F0404),
                    ],
              stops: value ? const [0.0, 0.5, 1.0] : const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 0,
                offset: const Offset(0, -0.5),
              ),
              if (value)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: -3,
                ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: value ? 0.18 : 0.08),
              width: 0.6,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(_pad),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF3F3F3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 0,
                          offset: const Offset(0, -0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: value ? 4 : 22,
                        right: value ? 22 : 4,
                      ),
                      child: Align(
                        alignment:
                            value ? Alignment.centerLeft : Alignment.centerRight,
                        child: Text(
                          value ? 'on' : 'off',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.96),
                            height: 1,
                            letterSpacing: 0.35,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                offset: const Offset(0, 0.5),
                                blurRadius: 1.5,
                              ),
                            ],
                          ),
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
