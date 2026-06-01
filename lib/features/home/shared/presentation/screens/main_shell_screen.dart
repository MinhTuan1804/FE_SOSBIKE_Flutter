import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/local/mechanic_order_flow_store.dart';
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
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_repair_confirm_view.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_payment_complete_view.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/mechanic_dev_flow.dart';
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
  bool _quoteSent = false;

  static const _incomingRequest = IncomingRescueRequest.sample;

  void _openIncomingRequest() {
    setState(() => _showIncomingRequest = true);
  }

  void _closeIncomingRequest() {
    if (!_showIncomingRequest) return;
    setState(() => _showIncomingRequest = false);
  }

  void _acceptIncomingRequest() async {
    _closeIncomingRequest();
    final repair = context.read<MechanicRepairProvider>();
    final ok = await repair.acceptDevIncomingOrder();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repair.errorMessage ?? 'Không nhận được đơn test')),
      );
      return;
    }
    setState(() {
      _orderFlow = _MechanicOrderFlow.accept;
      _tab = MainNavTab.orders;
      _quoteSent = false;
    });
  }

  bool _isQuoteSentPhase(String? orderStatus) {
    if (_quoteSent) return true;
    final s = orderStatus?.toUpperCase();
    return s == 'QUOTING' || s == 'REPAIRING';
  }

  bool _canStartRepairFromInspect(String? orderStatus) {
    if (!kDevSkipCustomerQuoteConfirm) return false;
    return _isQuoteSentPhase(orderStatus);
  }

  void _cancelOrderFlow() {
    unawaited(MechanicOrderFlowStore.clear());
    setState(() {
      _orderFlow = _MechanicOrderFlow.none;
      _selectedRepairItems = const [];
      _sessionSpareParts = const [];
      _quoteSent = false;
    });
  }

  Future<void> _saveFlowSnapshot() async {
    final orderId = context.read<MechanicRepairProvider>().activeOrderId;
    if (orderId == null || _orderFlow == _MechanicOrderFlow.none) return;

    await MechanicOrderFlowStore.save(
      MechanicOrderFlowSnapshot(
        orderId: orderId,
        flowStep: _orderFlow.name,
        selectedServiceIds: _selectedRepairItems.map((e) => e.id).toList(),
        sparePartJson: _sessionSpareParts
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'price': p.price,
                if (p.catalogPartId != null) 'catalogPartId': p.catalogPartId,
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> _goHomeFromFlow() async {
    await _saveFlowSnapshot();
    if (!mounted) return;
    setState(() {
      _orderFlow = _MechanicOrderFlow.none;
      _tab = MainNavTab.orders;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu tiến độ. Vào Lịch sử để tiếp tục đơn.')),
    );
  }

  _MechanicOrderFlow _flowFromOrderStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACCEPTED':
        return _MechanicOrderFlow.arrival;
      case 'ARRIVED':
      case 'QUOTING':
        return _MechanicOrderFlow.inspect;
      case 'REPAIRING':
        return _MechanicOrderFlow.repair;
      default:
        return _MechanicOrderFlow.accept;
    }
  }

  Future<void> _resumeOrderFlow() async {
    final repair = context.read<MechanicRepairProvider>();
    await repair.loadActiveOrder();
    if (!mounted || !repair.hasActiveOrder) return;

    final snapshot = await MechanicOrderFlowStore.load();
    final orderId = repair.activeOrderId!;

    _MechanicOrderFlow step;
    if (snapshot != null && snapshot.orderId == orderId) {
      step = _MechanicOrderFlow.values.firstWhere(
        (e) => e.name == snapshot.flowStep,
        orElse: () => _flowFromOrderStatus(repair.activeOrder?.status),
      );
    } else {
      step = _flowFromOrderStatus(repair.activeOrder?.status);
    }

    if (step == _MechanicOrderFlow.inspect || step == _MechanicOrderFlow.repair || step == _MechanicOrderFlow.complete) {
      await repair.loadServices(force: true);
      await repair.loadSpareParts(force: true);
    }

    var selected = _selectedRepairItems;
    var spareParts = _sessionSpareParts;

    if (snapshot != null && snapshot.orderId == orderId && snapshot.selectedServiceIds.isNotEmpty) {
      selected = repair.services
          .where((s) => snapshot.selectedServiceIds.contains(s.id))
          .map((s) => s.copyWith(selected: true))
          .toList();
      spareParts = snapshot.sparePartJson
          .map(
            (p) => p['catalogPartId'] != null
                ? MechanicSessionSparePart.fromCatalog(
                    partId: p['catalogPartId'].toString(),
                    name: p['name']?.toString() ?? '',
                    price: (p['price'] as num?)?.toInt() ?? 0,
                  )
                : MechanicSessionSparePart(
                    id: p['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    name: p['name']?.toString() ?? '',
                    price: (p['price'] as num?)?.toInt() ?? 0,
                  ),
          )
          .toList();
    } else if (step == _MechanicOrderFlow.repair || step == _MechanicOrderFlow.inspect) {
      final restored = await repair.restoreQuoteState();
      if (restored.services.isNotEmpty) selected = restored.services;
      if (restored.parts.isNotEmpty) spareParts = restored.parts;
    }

    if (!mounted) return;
    final quoteSent = _isQuoteSentPhase(repair.activeOrder?.status);
    setState(() {
      _selectedRepairItems = selected;
      _sessionSpareParts = spareParts;
      _orderFlow = step;
      _tab = MainNavTab.orders;
      _quoteSent = quoteSent;
    });
  }

  void _goToArrivalFlow() {
    setState(() => _orderFlow = _MechanicOrderFlow.arrival);
  }

  void _goToInspectFlow() {
    unawaited(context.read<MechanicRepairProvider>().loadSpareParts(force: true));
    setState(() => _orderFlow = _MechanicOrderFlow.inspect);
  }

  Future<void> _submitQuoteForCustomer(List<MechanicRepairLineItem> items) async {
    setState(() => _selectedRepairItems = items);
    final repair = context.read<MechanicRepairProvider>();
    final saved = await repair.saveQuote(
      selectedServices: items,
      spareParts: _sessionSpareParts,
    );
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repair.errorMessage ?? 'Không gửi được báo giá')),
      );
      return;
    }
    if (kDevSkipCustomerQuoteConfirm) {
      setState(() => _quoteSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi báo giá. Bấm Bắt đầu sửa để sang bước sửa chữa.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi báo giá. Chờ khách xác nhận trước khi hoàn thành sửa chữa.')),
    );
  }

  void _addSessionSparePart(MechanicSessionSparePart part) {
    setState(() => _sessionSpareParts = [..._sessionSpareParts, part]);
  }

  void _removeSessionSparePart(String partId) {
    setState(() => _sessionSpareParts = _sessionSpareParts.where((p) => p.id != partId).toList());
  }

  Future<void> _startRepairAfterQuote() async {
    final repair = context.read<MechanicRepairProvider>();
    final ok = await repair.startRepair();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repair.errorMessage ?? 'Không bắt đầu được sửa chữa')),
      );
      return;
    }
    setState(() => _orderFlow = _MechanicOrderFlow.repair);
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

  Future<void> _confirmArrived() async {
    final repair = context.read<MechanicRepairProvider>();
    final ok = await repair.confirmArrival();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repair.errorMessage ?? 'Không xác nhận được đến nơi')),
      );
      return;
    }
    unawaited(repair.loadServices(force: true));
    unawaited(repair.loadSpareParts(force: true));
    _goToInspectFlow();
  }

  void _finishOrderFlow() {
    unawaited(context.read<MechanicRepairProvider>().clearActiveOrderState());
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
    final inOrderFlow = auth.userType != 'CUSTOMER' && _orderFlow != _MechanicOrderFlow.none;
    final showMainHeader = !(_tab == MainNavTab.maintenance && auth.userType == 'CUSTOMER') && !inOrderFlow;

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
        if (!inOrderFlow)
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
                    unawaited(context.read<MechanicRepairProvider>().loadActiveOrder());
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
    final contentBottomPad = inOrderFlow ? 0.0 : navH * 0.35;

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
            onGoHome: _goHomeFromFlow,
          ),
        _MechanicOrderFlow.arrival => MechanicArrivalView(
            request: _incomingRequest,
            onBack: () => setState(() => _orderFlow = _MechanicOrderFlow.accept),
            onArrived: _confirmArrived,
            onGoHome: _goHomeFromFlow,
          ),
        _MechanicOrderFlow.inspect => MechanicInspectVehicleView(
            key: ValueKey(
              'inspect-${_quoteSent}-${_selectedRepairItems.map((e) => e.id).join('-')}-${_sessionSpareParts.length}',
            ),
            initialItems: repairProvider.services,
            preselectedItems: _selectedRepairItems,
            spareParts: _sessionSpareParts,
            catalogSpareParts: repairProvider.catalogSpareParts,
            isLoadingServices: repairProvider.isLoadingServices,
            isLoadingCatalog: repairProvider.isLoadingSpareParts,
            isSubmitting: repairProvider.isSubmitting,
            quoteSent: _isQuoteSentPhase(repairProvider.activeOrder?.status),
            onBack: () => setState(() => _orderFlow = _MechanicOrderFlow.arrival),
            onGoHome: _goHomeFromFlow,
            onAddSparePart: _addSessionSparePart,
            onRemoveSparePart: _removeSessionSparePart,
            onComplete: _submitQuoteForCustomer,
            onStartRepair: _canStartRepairFromInspect(repairProvider.activeOrder?.status)
                ? _startRepairAfterQuote
                : null,
          ),
        _MechanicOrderFlow.repair => MechanicRepairConfirmView(
            selectedServices: _selectedRepairItems,
            spareParts: _sessionSpareParts,
            catalogSpareParts: repairProvider.catalogSpareParts,
            isSubmitting: repairProvider.isSubmitting,
            isLoadingCatalog: repairProvider.isLoadingSpareParts,
            onBack: () => setState(() => _orderFlow = _MechanicOrderFlow.inspect),
            onGoHome: _goHomeFromFlow,
            onAddMoreServices: () => setState(() => _orderFlow = _MechanicOrderFlow.inspect),
            onAddSparePart: _addSessionSparePart,
            onRemoveSparePart: _removeSessionSparePart,
            onCompleteRepair: _completeRepairFlow,
          ),
        _MechanicOrderFlow.complete => MechanicPaymentCompleteView(
            onFinish: _finishOrderFlow,
            onGoHome: _goHomeFromFlow,
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
          : MechanicCustomerHistoryTab(onContinueOrder: _resumeOrderFlow),
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
