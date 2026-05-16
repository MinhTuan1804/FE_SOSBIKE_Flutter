import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/presentation/screens/home_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/presentation/screens/main_placeholder_tab.dart';
import 'package:fe_moblie_flutter/features/home/presentation/widgets/main_app_header.dart';
import 'package:fe_moblie_flutter/features/home/presentation/widgets/main_bottom_nav_bar.dart';

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
                isOnline: _isOnline,
                onOnlineChanged: (v) => setState(() => _isOnline = v),
                onAvatarTap: () => _confirmLogout(context),
              ),
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: navH * 0.35),
                          child: _buildBody(),
                        ),
                      ),
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
              color: Colors.transparent,
              clipBehavior: Clip.none,
              child: MainBottomNavBar(
                current: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) navigateToLogin();
    }
  }

  Widget _buildBody() {
    return switch (_tab) {
      MainNavTab.orders => const HomeDashboardTab(),
      MainNavTab.history => const MainPlaceholderTab(
          title: 'Lịch sử',
          iconAsset: 'assets/images/main/nav_history.png',
        ),
      MainNavTab.wallet => const MainPlaceholderTab(
          title: 'Ví quản lí',
          iconAsset: 'assets/images/main/nav_wallet.png',
        ),
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
