import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

enum MainNavTab { orders, history, wallet, maintenance }

/// Bottom nav [#D02121]: thanh phẳng + gờ tròn nhô (tab chọn) trên nền trong suốt.
class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final MainNavTab current;
  final ValueChanged<MainNavTab> onChanged;

  static const _bumpRadius = 40.0;
  /// Phần đường kính vòng tròn gắn trong thanh (0.8 → ~20% nhô lên mép thanh).
  static const _bumpInBarFraction = 0.8;
  static const _barHeight = 52.0;
  static const _tabCount = 4;
  static const _corner = 22.0;

  static double get _bumpProtrusion =>
      (1 - _bumpInBarFraction) * 2 * _bumpRadius;

  static double _circleBottom(double barTopFromStackBottom) =>
      barTopFromStackBottom - (1 + _bumpInBarFraction) * _bumpRadius;

  static const _items = [
    (MainNavTab.orders, 'assets/images/main/nav_orders.png'),
    (MainNavTab.history, 'assets/images/main/nav_history.png'),
    (MainNavTab.wallet, 'assets/images/main/nav_wallet.png'),
    (MainNavTab.maintenance, 'assets/images/main/nav_maintenance.png'),
  ];

  static double get _contentHeight => _barHeight + _bumpProtrusion;

  static double totalHeight(double bottomInset) => _contentHeight + bottomInset;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final totalH = totalHeight(bottom);
    final slotW = width / _tabCount;
    final cx = slotW * current.index + slotW / 2;
    final barTop = _barHeight + bottom;

    return SizedBox(
      width: width,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottom,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_corner),
                  bottomRight: Radius.circular(_corner),
                ),
              ),
            ),
          ),
          Positioned(
            left: cx - _bumpRadius,
            bottom: _circleBottom(barTop),
            width: _bumpRadius * 2,
            height: _bumpRadius * 2,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            height: _contentHeight,
            child: Row(
              children: _items.map((item) {
                return Expanded(
                  child: _NavSlot(
                    iconAsset: item.$2,
                    selected: current == item.$1,
                    onTap: () => onChanged(item.$1),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: MainBottomNavBar._contentHeight,
        width: double.infinity,
        child: selected
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Center(
                  child: Image.asset(
                    iconAsset,
                    height: 48,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              )
            : Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Image.asset(
                    iconAsset,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
      ),
    );
  }
}
