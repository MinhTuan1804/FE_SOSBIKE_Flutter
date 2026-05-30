import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_customer_history_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_activity_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_wallet_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/customer_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/screens/main_placeholder_tab.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_app_header.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_bottom_nav_bar.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/screens/membership_screen.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/screens/notifications_tab_screen.dart';
import 'package:fe_moblie_flutter/core/widgets/page_loader.dart';
import 'package:fe_moblie_flutter/core/widgets/app_background.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_accept_order_screen.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_arrival_screen.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_session_spare_part.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_inspect_vehicle_view.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_payment_complete_view.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_repair_confirm_view.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_incoming_request_popup.dart';

enum _MechanicOrderFlow { none, accept, arrival, inspect, repair, complete }

/// Shell sau đăng nhập: header + nội dung tab + bottom nav + FAB SOS (Figma).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  MainNavTab _tab = MainNavTab.orders;
  bool _isOnline = false;
  bool _showIncomingRequest = false;
  _MechanicOrderFlow _orderFlow = _MechanicOrderFlow.none;
  List<MechanicRepairLineItem> _selectedRepairItems = const [];
  List<MechanicSessionSparePart> _sessionSpareParts = const [];
  bool _editingRepairItems = false;

  static const _incomingRequest = IncomingRescueRequest.sample;

  void _openIncomingRequest() {
    setState(() => _showIncomingRequest = true);
  }

  void _closeIncomingRequest() {
    if (!_showIncomingRequest) return;
    setState(() => _showIncomingRequest = false);
  }

  void _acceptIncomingRequest() {
    _closeIncomingRequest();
    unawaited(context.read<MechanicRepairProvider>().loadActiveOrder());
    setState(() {
      _orderFlow = _MechanicOrderFlow.accept;
      _tab = MainNavTab.orders;
    });
  }

  void _cancelOrderFlow() {
    setState(() {
      _orderFlow = _MechanicOrderFlow.none;
      _selectedRepairItems = const [];
      _sessionSpareParts = const [];
      _editingRepairItems = false;
    });
  }

  void _goToArrivalFlow() {
    setState(() => _orderFlow = _MechanicOrderFlow.arrival);
  }

  void _goToInspectFlow({bool editingDuringRepair = false}) {
    setState(() {
      _editingRepairItems = editingDuringRepair;
      _orderFlow = _MechanicOrderFlow.inspect;
    });
  }

  void _goToRepairFlow(List<MechanicRepairLineItem> items) {
    final selected = items.isEmpty
        ? MechanicRepairLineItem.sampleServices.where((e) => e.id == '1').toList()
        : items;
    unawaited(context.read<MechanicRepairProvider>().loadSpareParts(force: true));
    unawaited(
      context.read<MechanicRepairProvider>().saveQuote(
            selectedServices: selected,
            spareParts: _sessionSpareParts,
          ),
    );
    setState(() {
      _selectedRepairItems = selected;
      _editingRepairItems = false;
      _orderFlow = _MechanicOrderFlow.repair;
    });
  }

  void _addSessionSparePart(MechanicSessionSparePart part) {
    setState(() => _sessionSpareParts = [..._sessionSpareParts, part]);
  }

  void _removeSessionSparePart(String partId) {
    setState(() => _sessionSpareParts = _sessionSpareParts.where((p) => p.id != partId).toList());
  }

  Future<void> _completeRepairFlow() async {
    final repair = context.read<MechanicRepairProvider>();
    final ok = await repair.completeRepair(
      selectedServices: _selectedRepairItems,
      spareParts: _sessionSpareParts,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repair.errorMessage ?? 'Không thể hoàn thành sửa chữa')),
      );
      return;
    }
    setState(() => _orderFlow = _MechanicOrderFlow.complete);
  }

  void _confirmArrived() {
    unawaited(context.read<MechanicRepairProvider>().loadServices(force: true));
    _goToInspectFlow();
  }

  void _finishOrderFlow() {
    _cancelOrderFlow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hoàn thành chuyến đi!')),
    );
  }

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
    final showMainHeader = !(_tab == MainNavTab.maintenance && auth.userType == 'CUSTOMER');

    final shellBody = Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            if (showMainHeader)
              MainAppHeader(
                userName: auth.displayName,
                avatarUrl: auth.avatarUrl,
                isOnline: _isOnline,
                onOnlineChanged: (v) => setState(() => _isOnline = v),
                userType: auth.userType,
                onAvatarTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const PageLoader(child: ProfileScreen()),
                    ),
                  );
                },
              ),
            Expanded(
              child: auth.userType == 'CUSTOMER'
                  ? ColoredBox(
                      color: Colors.white,
                      child: _buildTabStack(navH),
                    )
                  : _buildTabStack(navH),
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
              onChanged: (t) {
                setState(() => _tab = t);
                if (t == MainNavTab.history && auth.userType != 'CUSTOMER') {
                  context.read<MechanicHistoryProvider>().load(force: true);
                }
                if (t == MainNavTab.wallet && auth.userType != 'CUSTOMER') {
                  context.read<MechanicWalletProvider>().load(force: true);
                }
              },
              userType: auth.userType,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: auth.userType == 'CUSTOMER' ? Colors.white : const Color(0xFF8B1A1A),
      body: auth.userType == 'CUSTOMER'
          ? shellBody
          : AppBackground(child: shellBody),
    );
  }

  Widget _buildTabStack(double navH) {
    final auth = context.watch<AuthProvider>();
    final inOrderFlow = auth.userType != 'CUSTOMER' && _orderFlow != _MechanicOrderFlow.none;
    final contentBottomPad = inOrderFlow ? navH : navH * 0.35;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(bottom: contentBottomPad),
            child: _buildBody(auth.userType),
          ),
        ),
        if (auth.userType != 'CUSTOMER' &&
            _orderFlow == _MechanicOrderFlow.none &&
            _showIncomingRequest) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeIncomingRequest,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: navH + 76,
            child: MechanicIncomingRequestPopup(
              request: _incomingRequest,
              onCancel: _closeIncomingRequest,
              onAccept: _acceptIncomingRequest,
              onViewMore: _closeIncomingRequest,
            ),
          ),
        ],
        if (auth.userType != 'CUSTOMER' && _orderFlow == _MechanicOrderFlow.none)
          Positioned(
            right: 12,
            bottom: navH + 8,
            child: _SosFab(onPressed: _openIncomingRequest),
          ),
      ],
    );
  }

  Widget _buildBody(String? userType) {
    final repairProvider = context.watch<MechanicRepairProvider>();

    if (userType != 'CUSTOMER' && _orderFlow != _MechanicOrderFlow.none) {
      return switch (_orderFlow) {
        _MechanicOrderFlow.accept => MechanicAcceptOrderView(
            request: _incomingRequest,
            onCancel: _cancelOrderFlow,
            onGoNow: _goToArrivalFlow,
          ),
        _MechanicOrderFlow.arrival => MechanicArrivalView(
            request: _incomingRequest,
            onBack: () => setState(() => _orderFlow = _MechanicOrderFlow.accept),
            onArrived: _confirmArrived,
          ),
        _MechanicOrderFlow.inspect => MechanicInspectVehicleView(
            key: ValueKey(
              'inspect-${_selectedRepairItems.map((e) => e.id).join('-')}-$_editingRepairItems',
            ),
            initialItems: repairProvider.services,
            preselectedItems: _selectedRepairItems,
            editingDuringRepair: _editingRepairItems,
            isLoadingServices: repairProvider.isLoadingServices,
            onBack: () => setState(() {
              if (_editingRepairItems) {
                _editingRepairItems = false;
                _orderFlow = _MechanicOrderFlow.repair;
              } else {
                _orderFlow = _MechanicOrderFlow.arrival;
              }
            }),
            onStartRepair: _goToRepairFlow,
          ),
        _MechanicOrderFlow.repair => MechanicRepairConfirmView(
            selectedServices: _selectedRepairItems,
            spareParts: _sessionSpareParts,
            catalogSpareParts: repairProvider.catalogSpareParts,
            isSubmitting: repairProvider.isSubmitting,
            isLoadingCatalog: repairProvider.isLoadingSpareParts,
            onBack: () => _goToInspectFlow(editingDuringRepair: true),
            onAddMoreServices: () => _goToInspectFlow(editingDuringRepair: true),
            onAddSparePart: _addSessionSparePart,
            onRemoveSparePart: _removeSessionSparePart,
            onCompleteRepair: _completeRepairFlow,
          ),
        _MechanicOrderFlow.complete => MechanicPaymentCompleteView(
            onFinish: _finishOrderFlow,
          ),
        _MechanicOrderFlow.none => const SizedBox.shrink(),
      };
    }

    return switch (_tab) {
      MainNavTab.orders => userType == 'CUSTOMER'
          ? const CustomerDashboardTab()
          : const MechanicDashboardTab(),
      MainNavTab.history => userType == 'CUSTOMER'
          ? const MainPlaceholderTab(
              title: 'Lịch sử',
              iconAsset: 'assets/images/main/nav_history.png',
            )
          : const MechanicCustomerHistoryTab(),
      MainNavTab.wallet => userType == 'CUSTOMER'
          ? const MembershipScreen()
          : const MechanicWalletTab(),
      MainNavTab.maintenance => userType == 'CUSTOMER'
          ? const NotificationsTabScreen()
          : const MechanicActivityTab(),
    };
  }
}

class _SosFab extends StatefulWidget {
  const _SosFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SosFab> createState() => _SosFabState();
}

class _SosFabState extends State<_SosFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = _pulse.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  _GlowRing(size: 64 + t * 18, opacity: 0.22 * (1 - t)),
                  _GlowRing(size: 52 + t * 10, opacity: 0.32 * (1 - t)),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/main/fab_sos.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary,
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
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

class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: opacity),
      ),
    );
  }
}
