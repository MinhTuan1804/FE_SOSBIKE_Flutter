import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

enum MainNavTab { orders, history, wallet, maintenance }

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.current,
    required this.onChanged,
    required this.userType,
    this.showActive = true,
    this.unreadNotificationCount = 0,
  });

  final MainNavTab current;
  final ValueChanged<MainNavTab> onChanged;
  final String? userType;
  final bool showActive;
  final int unreadNotificationCount;

  static const _barHeight = 65.0;
  static const _bumpRadius = 34.0;
  static const _bumpProtrusion = 18.0;
  static const _tabIconSize = 45.0;
  static const _wheelSize = 22.0;
  static const _tabCount = 4;
  static const _corner = 24.0;

  static double totalHeight(double bottomInset) => _barHeight + _bumpProtrusion + bottomInset;

  static const _items = [
    (MainNavTab.orders, 'assets/images/main/nav_orders.png'),
    (MainNavTab.history, 'assets/images/main/nav_history.png'),
    (MainNavTab.wallet, 'assets/images/main/nav_wallet.png'),
    (MainNavTab.maintenance, 'assets/images/main/nav_maintenance.png'),
  ];

  static const _customerItems = [
    (MainNavTab.orders, 'assets/images/main/customer_home_tab.png'),
    (MainNavTab.history, 'assets/images/main/nav_history.png'),
    (MainNavTab.wallet, 'assets/images/main/customer_home_thanhtoan.png'),
    (MainNavTab.maintenance, 'assets/images/main/customer_home_thongbao.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final totalH = _barHeight + _bumpProtrusion + bottom;
    final slotW = width / _tabCount;
    final activeIndex = showActive ? current.index : 100;
    final cx = slotW * activeIndex + slotW / 2;
    final circleBottom = bottom + _barHeight - _bumpRadius + _bumpProtrusion;

    final isCustomer = userType?.toUpperCase() == 'CUSTOMER';
    final itemsToUse = isCustomer ? _customerItems : _items;

    return SizedBox(
      width: width,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Flat bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: -18,
            height: _barHeight + bottom + 30,
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

          // Animated Bump Circle
          if (showActive)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: cx - _bumpRadius,
              bottom: circleBottom,
              width: _bumpRadius + 35,
              height: _bumpRadius + 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

          // Animated Floating Wheel Icon
          if (showActive)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: cx - (_wheelSize / 2),
              bottom: circleBottom + (_bumpRadius * 2) - 18,
              child: Image.asset(
                'assets/images/main/fab_wheel.png',
                width: _wheelSize,
                height: _wheelSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: _wheelSize,
                ),
              ),
            ),

          // Tabs
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            height: _barHeight + _bumpProtrusion,
            child: Row(
              children: itemsToUse.map((item) {
                final isSelected = showActive && current == item.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(item.$1),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: double.infinity,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Icon animated up/down
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            bottom: isSelected ? 36.0 : 20.0,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  item.$2,
                                  height: _tabIconSize,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _getFallbackIcon(item.$1),
                                    color: Colors.white,
                                    size: _tabIconSize,
                                  ),
                                ),
                                if (item.$1 == MainNavTab.maintenance && unreadNotificationCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.white, width: 1.2),
                                      ),
                                      child: Text(
                                        unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  IconData _getFallbackIcon(MainNavTab tab) {
    return switch (tab) {
      MainNavTab.orders => Icons.home_rounded,
      MainNavTab.history => Icons.history,
      MainNavTab.wallet => Icons.account_balance_wallet_rounded,
      MainNavTab.maintenance => Icons.notifications_rounded,
    };
  }
}
