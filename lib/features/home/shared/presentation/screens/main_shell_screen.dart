import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/customer_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/screens/main_placeholder_tab.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_app_header.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_bottom_nav_bar.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/screens/membership_screen.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/screens/profile_screen.dart';

/// Shell sau đăng nhập: header + nội dung tab + bottom nav + FAB SOS (Figma).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  MainNavTab _tab = MainNavTab.orders;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await context.read<AuthProvider>().fetchMyProfile(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final navH = MainBottomNavBar.totalHeight(bottomPad);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              MainAppHeader(
                userName: auth.displayName,
                avatarUrl: auth.avatarUrl,
                isOnline: _isOnline,
                onOnlineChanged: (v) => setState(() => _isOnline = v),
                userType: auth.userType,
                onAvatarTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              Expanded(
                child: ColoredBox(
                  color: auth.userType == 'CUSTOMER' ? Colors.white : Colors.black,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: navH * 0.35),
                          child: _buildBody(auth.userType),
                        ),
                      ),
                      if (auth.userType != 'CUSTOMER')
                        Positioned(
                          right: 12,
                          bottom: navH + 8,
                          child: _SosFab(onPressed: () {}),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primary,
              clipBehavior: Clip.none,
              child: MainBottomNavBar(
                current: _tab,
                onChanged: (t) => setState(() => _tab = t),
                userType: auth.userType,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String? userType) {
    return switch (_tab) {
      MainNavTab.orders => userType == 'CUSTOMER'
          ? const CustomerDashboardTab()
          : const MechanicDashboardTab(),
      MainNavTab.history => const MainPlaceholderTab(
          title: 'Lịch sử',
          iconAsset: 'assets/images/main/nav_history.png',
        ),
      MainNavTab.wallet => const MembershipScreen(),
      MainNavTab.maintenance => const MainPlaceholderTab(
          title: 'Bảo trì',
          iconAsset: 'assets/images/main/nav_maintenance.png',
        ),
    };
  }
}

class _SosFab extends StatelessWidget {
  const _SosFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 64,
        height: 64,
        child: ClipOval(
          child: Image.asset(
            'assets/images/main/fab_sos.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.primary,
              child: const Icon(Icons.notifications_active, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
