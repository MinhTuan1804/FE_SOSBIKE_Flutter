import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/config/app_config_provider.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/profile/data/models/user_profile_models.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/local/mechanic_order_flow_store.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_customer_history_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_activity_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_wallet_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/customer_dashboard_tab.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/customer_wallet_tab.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/customer_order_history_tab.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/customer_history_provider.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_app_header.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_bottom_nav_bar.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/screens/notifications_tab_screen.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_setup_profile_screen.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/notification_provider.dart';
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
  State<MainShellScreen> createState() => MainShellScreenState();
}

class MainShellScreenState extends State<MainShellScreen> {
  late RescueProvider _rescueProvider;
  MainNavTab _tab = MainNavTab.orders;

  void setTab(MainNavTab tab) {
    setState(() {
      _tab = tab;
    });
  }
  _MechanicOrderFlow _orderFlow = _MechanicOrderFlow.none;
  List<MechanicRepairLineItem> _selectedRepairItems = const [];
  List<MechanicSessionSparePart> _sessionSpareParts = const [];
  bool _quoteSent = false;
  IncomingRescueRequest? _activeIncomingRequest;

  void _openIncomingRequest() {
    context.read<RescueProvider>().simulateIncomingRequest({
      'orderId': '123e4567-e89b-12d3-a456-426614174000',
      'customerName': 'Khánh Linh',
      'requestAddress': 'Chung cư Petroland, đường 62, phường Bình Trưng, Thành phố Thủ Đức.',
      'distance': 0.4003,
      'customerPhone': '0123456789',
      'latitude': 10.765622,
      'longitude': 106.663172,
    });
  }

  void _closeIncomingRequest() {
    context.read<RescueProvider>().dismissIncomingRequest();
  }

  Future<void> _acceptIncomingRequest() async {
    final rescue = context.read<RescueProvider>();
    final req = rescue.incomingRequest;
    if (req == null) return;

    final incomingReq = IncomingRescueRequest(
      customerName: req['customerName'] ?? 'Khách hàng',
      address: req['requestAddress'] ?? '',
      fullAddress: req['requestAddress'] ?? '',
      distanceMeters: (req['distance'] as num? ?? 2.5) * 1000.0,
      serviceTypeLabel: 'LƯU ĐỘNG',
      phoneNumber: req['customerPhone'] ?? '0987654321',
      avatarUrl: req['customerAvatarUrl'],
      latitude: req['latitude'] != null ? (req['latitude'] as num).toDouble() : null,
      longitude: req['longitude'] != null ? (req['longitude'] as num).toDouble() : null,
    );

    final res = await rescue.acceptRescueOrder(req['orderId']);
    if (res != null) {
      setState(() {
        _activeIncomingRequest = incomingReq;
        _orderFlow = _MechanicOrderFlow.accept;
        _tab = MainNavTab.orders;
      });
      rescue.dismissIncomingRequest();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rescue.errorMessage ?? 'Không thể nhận đơn.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    IncomingRescueRequest? incomingReq;
    if (repair.activeOrder != null) {
      incomingReq = IncomingRescueRequest(
        customerName: repair.activeOrder!.customerName ?? 'Khách hàng',
        address: repair.activeOrder!.requestAddress,
        fullAddress: repair.activeOrder!.requestAddress,
        distanceMeters: 0,
        serviceTypeLabel: 'LƯU ĐỘNG',
        phoneNumber: '0987654321',
        latitude: repair.activeOrder!.customerLatitude,
        longitude: repair.activeOrder!.customerLongitude,
      );

      final rescue = context.read<RescueProvider>();
      if (repair.activeOrder!.customerLatitude != null && repair.activeOrder!.customerLongitude != null) {
        rescue.setActiveCustomerCoords(
          repair.activeOrder!.customerLatitude!,
          repair.activeOrder!.customerLongitude!,
        );
      }
    }

    setState(() {
      _selectedRepairItems = selected;
      _sessionSpareParts = spareParts;
      _orderFlow = step;
      _tab = MainNavTab.orders;
      _quoteSent = quoteSent;
      if (incomingReq != null) {
        _activeIncomingRequest = incomingReq;
      }
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

  void _onRescueStatusChanged() {
    if (!mounted) return;
    final rescue = context.read<RescueProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.userType != 'CUSTOMER') {
      if (_orderFlow != _MechanicOrderFlow.none) {
        if (rescue.activeOrderStatus == 'CONFIRMED') {
          if (_orderFlow == _MechanicOrderFlow.accept) {
            setState(() {
              _orderFlow = _MechanicOrderFlow.arrival;
            });
            rescue.clearActiveOrderStatus();
          }
        } else if (rescue.activeOrderStatus == 'REPAIRING') {
          if (_orderFlow == _MechanicOrderFlow.inspect) {
            setState(() {
              _orderFlow = _MechanicOrderFlow.repair;
            });
            rescue.clearActiveOrderStatus();
          }
        } else if (rescue.activeOrderStatus == 'PAID') {
          if (_orderFlow != _MechanicOrderFlow.complete) {
            setState(() {
              _orderFlow = _MechanicOrderFlow.complete;
            });
          }
        } else if (rescue.activeOrderStatus == 'CANCELLED') {
          setState(() {
            _orderFlow = _MechanicOrderFlow.none;
            _activeIncomingRequest = null;
          });
          rescue.clearActiveOrderStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Khách hàng đã hủy đơn cứu hộ.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _rescueProvider = context.read<RescueProvider>();
    _rescueProvider.addListener(_onRescueStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await auth.fetchMyProfile(silent: true);
      if (!mounted) return;
      if (auth.userType?.toUpperCase() == 'CUSTOMER') {
        unawaited(context.read<MembershipProvider>().load());
      }
    });
  }

  @override
  void dispose() {
    _rescueProvider.removeListener(_onRescueStatusChanged);
    super.dispose();
  }

  bool _mechanicHasBankLinked(AuthProvider auth) {
    final wallet = auth.profile?.wallet;
    return wallet != null &&
        (wallet.bankName?.isNotEmpty ?? false) &&
        (wallet.bankAccountNumber?.isNotEmpty ?? false) &&
        (wallet.bankAccountHolder?.isNotEmpty ?? false);
  }

  bool _isMechanicWalletOnboarding(AuthProvider auth, MechanicWalletProvider walletProv) {
    if (auth.userType == 'CUSTOMER' || _tab != MainNavTab.wallet) return false;
    return walletProv.isInWalletSetupFlow(hasBankLinked: _mechanicHasBankLinked(auth));
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final walletProv = context.watch<MechanicWalletProvider>();
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final navH = MainBottomNavBar.totalHeight(bottomPad);
    final inOrderFlow = auth.userType != 'CUSTOMER' && _orderFlow != _MechanicOrderFlow.none;
    final inWalletSetup = _isMechanicWalletOnboarding(auth, walletProv);
    final hideShellChrome = inOrderFlow || inWalletSetup;
    final showMainHeader = !hideShellChrome && _tab == MainNavTab.orders;
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadNotificationCount = notificationProvider.incomingOrderUnreadCount;
    final membershipProvider = context.watch<MembershipProvider>();

    final rescueProvider = context.watch<RescueProvider>();

    final isMechanic = auth.userType?.toUpperCase() == 'MECHANIC';
    final showVipBadge = auth.userType?.toUpperCase() == 'CUSTOMER' &&
        membershipProvider.currentSubscription != null &&
        membershipProvider.currentSubscription!.price > 0;
    if (isMechanic) {
      final isVerified = auth.profile?.mechanic?.isVerified ?? false;
      if (!isVerified) {
        if (auth.profile == null && auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF8B1A1A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFF8B1A1A),
          body: AppBackground(
            child: _buildLockoutScreen(context, auth),
          ),
        );
      }
    }

    final shellBody = Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            if (showMainHeader)
              MainAppHeader(
                userName: auth.displayName,
                avatarUrl: auth.avatarUrl,
                isOnline: rescueProvider.isOnline,
                onOnlineChanged: (v) => context.read<RescueProvider>().toggleOnlineStatus(v),
                userType: auth.userType,
                showVipBadge: showVipBadge,
                onAvatarTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const PageLoader(child: ProfileScreen()),
                    ),
                  );
                },
              ),
            Expanded(child: _buildTabStack(navH)),
          ],
        ),
        if (!hideShellChrome)
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
                  if (t == MainNavTab.history && auth.userType == 'CUSTOMER') {
                    context.read<CustomerHistoryProvider>().load(force: true);
                  }
                  if (t == MainNavTab.wallet) {
                    if (auth.userType == 'CUSTOMER') {
                      context.read<MembershipProvider>().load();
                    } else {
                      final walletProv = context.read<MechanicWalletProvider>();
                      walletProv.lockWallet();
                      walletProv.load(force: true);
                    }
                  }
                },
                userType: auth.userType,
                unreadNotificationCount: unreadNotificationCount,
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF8B1A1A),
      body: AppBackground(child: shellBody),
    );
  }

  Future<void> _checkApprovalStatus(BuildContext context, AuthProvider auth) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final profile = await auth.fetchMyProfile(silent: true);

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Không kiểm tra được trạng thái. Vui lòng thử lại.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final isVerified = profile.mechanic?.isVerified ?? false;
    if (isVerified) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.verified_rounded, color: Colors.green, size: 40),
          title: const Text('Đã được duyệt!'),
          content: const Text(
            'Tài khoản thợ của bạn đã được admin phê duyệt.\n'
            'Bạn có thể bắt đầu nhận đơn ngay bây giờ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    final missing = _missingMechanicProfileItems(profile);
    final message = missing.isEmpty
        ? 'Hồ sơ của bạn đã đủ thông tin và đang chờ admin SOSBIKE phê duyệt.\n'
            'Thường mất 1–2 ngày làm việc.'
        : 'Hồ sơ chưa đủ thông tin. Vui lòng bổ sung:\n\n'
            '${missing.map((item) => '• $item').join('\n')}';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          missing.isEmpty ? Icons.hourglass_top_rounded : Icons.assignment_late_outlined,
          color: missing.isEmpty ? Colors.orange : AppColors.primary,
          size: 40,
        ),
        title: Text(missing.isEmpty ? 'Đang chờ duyệt' : 'Hồ sơ chưa đủ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          if (missing.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MechanicSetupProfileScreen(),
                  ),
                ).then((_) => auth.fetchMyProfile(silent: true));
              },
              child: const Text(
                'Hoàn thiện hồ sơ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _missingMechanicProfileItems(UserProfileDto profile) {
    final mech = profile.mechanic;
    final wallet = profile.wallet;
    final missing = <String>[];

    if (mech == null) {
      missing.add('Hồ sơ thợ');
      return missing;
    }

    bool hasUrl(String? url) => url != null && url.trim().isNotEmpty;

    if (!hasUrl(mech.cccdFrontUrl)) missing.add('CCCD mặt trước');
    if (!hasUrl(mech.cccdBackUrl)) missing.add('CCCD mặt sau');
    if (!hasUrl(profile.avatarUrl)) missing.add('Ảnh chân dung');
    if (mech.vehicleModel == null || mech.vehicleModel!.trim().isEmpty) {
      missing.add('Mẫu xe');
    }
    if (mech.licensePlate.trim().isEmpty) missing.add('Biển số xe');
    if (mech.driverLicenseNumber == null || mech.driverLicenseNumber!.trim().isEmpty) {
      missing.add('Số GPLX');
    }
    if (!hasUrl(mech.vehicleRegistrationUrl)) missing.add('Đăng ký xe (cà vẹt)');
    if (!hasUrl(mech.driverLicenseUrl)) missing.add('Ảnh bằng lái xe');

    final bankOk = wallet != null &&
        (wallet.bankName?.trim().isNotEmpty ?? false) &&
        (wallet.bankAccountNumber?.trim().isNotEmpty ?? false) &&
        (wallet.bankAccountHolder?.trim().isNotEmpty ?? false);
    if (!bankOk) missing.add('Tài khoản ngân hàng');

    return missing;
  }

  Widget _buildLockoutScreen(BuildContext context, AuthProvider auth) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tài khoản chưa được duyệt',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Hồ sơ đăng ký của bạn đang chờ Admin SOSBIKE phê duyệt hoặc thông tin của bạn chưa được điền đầy đủ.\n\n'
              'Vui lòng bấm vào nút bên dưới để hoàn thiện thông tin xác thực (CCCD, Bằng lái, Đăng ký xe, Bảo hiểm & Ngân hàng) để kích hoạt tài khoản.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MechanicSetupProfileScreen(),
                    ),
                  ).then((_) {
                    auth.fetchMyProfile(silent: true);
                  });
                },
                icon: const Icon(Icons.assignment_ind_rounded, color: AppColors.primary),
                label: const Text(
                  'Hoàn thiện hồ sơ xác thực',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _checkApprovalStatus(context, auth),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Kiểm tra trạng thái duyệt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Đăng xuất', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await auth.logout();
                    if (context.mounted) {
                      navigateToLogin();
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabStack(double navH) {
    final auth = context.watch<AuthProvider>();
    final walletProv = context.watch<MechanicWalletProvider>();
    final appConfig = context.watch<AppConfigProvider>().config;
    final inOrderFlow = auth.userType != 'CUSTOMER' && _orderFlow != _MechanicOrderFlow.none;
    final inWalletSetup = _isMechanicWalletOnboarding(auth, walletProv);
    final hideShellChrome = inOrderFlow || inWalletSetup;
    final contentBottomPad = hideShellChrome ? 0.0 : navH * 0.35;

    final rescueProvider = context.watch<RescueProvider>();
    final reqMap = rescueProvider.incomingRequest;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (auth.userType == 'CUSTOMER' && _tab != MainNavTab.history && _tab != MainNavTab.wallet)
          Positioned.fill(
            child: _CustomerHomeBackground(backgroundUrl: appConfig.ui.homeBackgroundUrl),
          ),
        if (appConfig.flags.maintenanceMode)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD699)),
              ),
              child: const Text(
                'Hệ thống đang bảo trì. Một số chức năng có thể tạm thời bị giới hạn.',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(bottom: contentBottomPad),
            child: _buildBody(auth.userType),
          ),
        ),
        if (auth.userType != 'CUSTOMER' &&
            _orderFlow == _MechanicOrderFlow.none &&
            reqMap != null) ...[
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
              request: IncomingRescueRequest(
                customerName: reqMap['customerName'] ?? 'Khách hàng',
                address: reqMap['requestAddress'] ?? '',
                fullAddress: reqMap['requestAddress'] ?? '',
                distanceMeters: (reqMap['distance'] as num? ?? 2.5) * 1000.0,
                serviceTypeLabel: 'LƯU ĐỘNG',
                phoneNumber: reqMap['customerPhone'] ?? '0987654321',
                avatarUrl: reqMap['customerAvatarUrl'],
                latitude: reqMap['latitude'] != null ? (reqMap['latitude'] as num).toDouble() : null,
                longitude: reqMap['longitude'] != null ? (reqMap['longitude'] as num).toDouble() : null,
              ),
              onCancel: _closeIncomingRequest,
              onAccept: _acceptIncomingRequest,
              onViewMore: _closeIncomingRequest,
            ),
          ),
        ],
        if (auth.userType != 'CUSTOMER' &&
            _orderFlow == _MechanicOrderFlow.none &&
            !inWalletSetup &&
            appConfig.flags.sosEnabled)
          Positioned(
            right: -2,
            bottom: navH + 24,
            child: _SosFab(
              isActive: rescueProvider.incomingRequest != null,
              onPressed: _openIncomingRequest,
            ),
          ),
      ],
    );
  }

  Widget _buildBody(String? userType) {
    final repairProvider = context.watch<MechanicRepairProvider>();

    if (userType != 'CUSTOMER' && _orderFlow != _MechanicOrderFlow.none) {
      return switch (_orderFlow) {
        _MechanicOrderFlow.accept => MechanicAcceptOrderView(
            request: _activeIncomingRequest ?? IncomingRescueRequest.sample,
            onCancel: _cancelOrderFlow,
            onGoNow: _goToArrivalFlow,
            onGoHome: _goHomeFromFlow,
          ),
        _MechanicOrderFlow.arrival => MechanicArrivalView(
            request: _activeIncomingRequest ?? IncomingRescueRequest.sample,
            onBack: () {},
            onArrived: _confirmArrived,
            onGoHome: _goHomeFromFlow,
          ),
        _MechanicOrderFlow.inspect => MechanicInspectVehicleView(
            key: ValueKey(
              'inspect-$_quoteSent-${_selectedRepairItems.map((e) => e.id).join('-')}-${_sessionSpareParts.length}',
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
            orderId: repairProvider.activeOrderId ?? '',
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
          ? const CustomerOrderHistoryTab()
          : MechanicCustomerHistoryTab(onContinueOrder: _resumeOrderFlow),
      MainNavTab.wallet => userType == 'CUSTOMER'
          ? const CustomerWalletTab()
          : const MechanicWalletTab(),
      MainNavTab.maintenance => userType == 'CUSTOMER'
          ? const NotificationsTabScreen()
          : const MechanicActivityTab(previewOnly: false),
    };
  }
}

class _SosFab extends StatefulWidget {
  const _SosFab({required this.onPressed, required this.isActive});

  final VoidCallback onPressed;
  final bool isActive;

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
    const activeColor = Color(0xFF22C55E); // Green
    const inactiveColor = Color(0xFF9CA3AF); // Gray
    final dotColor = widget.isActive ? activeColor : inactiveColor;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = _pulse.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _GlowRing(
                      size: 64 + t * 18,
                      opacity: 0.22 * (1 - t),
                      color: AppColors.primary,
                    ),
                    _GlowRing(
                      size: 52 + t * 10,
                      opacity: 0.32 * (1 - t),
                      color: AppColors.primary,
                    ),
                  ],
                );
              },
            ),
          GestureDetector(
            onTap: widget.isActive ? widget.onPressed : null,
            child: Container(
              width: 70,
              height: 70,
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
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary,
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: Border.all(color: Colors.white, width: 2),
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
        ],
      ),
    );

  }
}

class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.size, required this.opacity, required this.color});

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

class _CustomerHomeBackground extends StatelessWidget {
  const _CustomerHomeBackground({required this.backgroundUrl});

  final String backgroundUrl;

  @override
  Widget build(BuildContext context) {
    final url = backgroundUrl.trim();
    if (url.isEmpty) {
      return const ColoredBox(color: Colors.white);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: CachedNetworkImageProvider(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.white),
        ),
        Container(
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ],
    );
  }
}
