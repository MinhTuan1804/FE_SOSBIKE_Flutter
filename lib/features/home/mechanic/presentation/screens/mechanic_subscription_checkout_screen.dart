import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_priority_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_subscription_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

/// Màn đăng ký / nâng cấp gói ưu tiên.
/// Điều hướng nội bộ qua 3 state: confirm → processing → result.
class MechanicSubscriptionCheckoutScreen extends StatefulWidget {
  const MechanicSubscriptionCheckoutScreen({super.key, required this.plan});

  final MechanicPriorityPlan plan;

  @override
  State<MechanicSubscriptionCheckoutScreen> createState() =>
      _MechanicSubscriptionCheckoutScreenState();
}

enum _CheckoutStep { confirm, processing, success, failure }

class _MechanicSubscriptionCheckoutScreenState
    extends State<MechanicSubscriptionCheckoutScreen> {
  _CheckoutStep _step = _CheckoutStep.confirm;
  _PaymentMethod _method = _PaymentMethod.wallet;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MechanicWalletProvider>().load(force: true);
    });
  }

  int get _walletBalance =>
      context.watch<MechanicWalletProvider>().data?.balance ?? 0;


  Future<void> _confirmPayment() async {
    if (widget.plan.planId == null) {
      setState(() {
        _failureMessage = 'Gói chưa được đồng bộ từ máy chủ.';
        _step = _CheckoutStep.failure;
      });
      return;
    }

    setState(() {
      _step = _CheckoutStep.processing;
      _failureMessage = null;
    });

    final subProv = context.read<MechanicSubscriptionProvider>();
    final ok = await subProv.subscribe(
      planId: widget.plan.planId!,
      paymentMethod: 'WALLET',
    );

    if (!mounted) return;

    if (ok) {
      await context.read<MechanicWalletProvider>().refresh();
      setState(() => _step = _CheckoutStep.success);
    } else {
      setState(() {
        _failureMessage = subProv.error ?? 'Thanh toán thất bại.';
        _step = _CheckoutStep.failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: switch (_step) {
        _CheckoutStep.confirm => _ConfirmScreen(
            key: ValueKey('confirm-$_walletBalance'),
            plan: widget.plan,
            walletBalance: _walletBalance,
            selectedMethod: _method,
            onMethodChanged: (m) => setState(() => _method = m),
            onBack: () => Navigator.of(context).pop(),
            onConfirm: _confirmPayment,
          ),
        _CheckoutStep.processing => const _ProcessingScreen(
            key: ValueKey('processing'),
          ),
        _CheckoutStep.success => _ResultScreen(
            key: const ValueKey('success'),
            plan: widget.plan,
            isSuccess: true,
            onDone: () => Navigator.of(context).pop(true),
          ),
        _CheckoutStep.failure => _ResultScreen(
            key: const ValueKey('failure'),
            plan: widget.plan,
            isSuccess: false,
            message: _failureMessage,
            onRetry: () => setState(() => _step = _CheckoutStep.confirm),
            onDone: () => Navigator.of(context).pop(false),
          ),
      },
    );
  }
}

// ─── Payment method enum ──────────────────────────────────────────────────────

enum _PaymentMethod { wallet, bank }

// ─── Screen 1: Confirm ───────────────────────────────────────────────────────

class _ConfirmScreen extends StatelessWidget {
  const _ConfirmScreen({
    super.key,
    required this.plan,
    required this.walletBalance,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.onBack,
    required this.onConfirm,
  });

  final MechanicPriorityPlan plan;
  final int walletBalance;
  final _PaymentMethod selectedMethod;
  final ValueChanged<_PaymentMethod> onMethodChanged;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  bool get _walletSufficient => walletBalance >= plan.priceValue;

  @override
  Widget build(BuildContext context) {
    final style = plan.style;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: Column(
        children: [
          // ── Header gradient ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: style.screenBackground,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Xác nhận đăng ký',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Plan summary pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: style.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: style.accent.withValues(alpha: 0.15),
                              border: Border.all(color: style.accent, width: 1.5),
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: style.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plan.periodLabel,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                plan.priceLabel,
                                style: TextStyle(
                                  color: style.priceColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                plan.periodLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Benefits recap
                  _SectionTitle(label: 'Quyền lợi nhận được', accent: style.accent),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1010),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: style.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: plan.benefits
                          .map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: style.accent,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment method
                  const _SectionTitle(
                    label: 'Phương thức thanh toán',
                    accent: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  _PaymentMethodTile(
                    method: _PaymentMethod.wallet,
                    selected: selectedMethod == _PaymentMethod.wallet,
                    balance: walletBalance,
                    sufficient: _walletSufficient,
                    onTap: () => onMethodChanged(_PaymentMethod.wallet),
                  ),
                  const SizedBox(height: 8),
                  _PaymentMethodTile(
                    method: _PaymentMethod.bank,
                    selected: selectedMethod == _PaymentMethod.bank,
                    balance: 0,
                    sufficient: true,
                    onTap: () => onMethodChanged(_PaymentMethod.bank),
                  ),

                  if (selectedMethod == _PaymentMethod.wallet && !_walletSufficient) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF4444).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF6B6B),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Số dư ví không đủ. Vui lòng nạp thêm hoặc chọn phương thức khác.',
                              style: TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Order summary
                  const _SectionTitle(label: 'Tóm tắt đơn hàng', accent: Colors.white),
                  const SizedBox(height: 10),
                  _OrderSummaryRow(label: 'Gói', value: plan.title),
                  _OrderSummaryRow(
                    label: 'Thời hạn',
                    value: plan.periodLabel.replaceAll('/', '').trim(),
                  ),
                  _OrderSummaryRow(label: 'Giá gốc', value: plan.priceLabel),
                  const _OrderSummaryRow(label: 'Giảm giá', value: '0đ'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFF3A1A1A)),
                  ),
                  _OrderSummaryRow(
                    label: 'Tổng thanh toán',
                    value: plan.priceLabel,
                    isTotal: true,
                    accent: style.priceColor,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Fixed bottom button ──
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A0A),
          border: Border(top: BorderSide(color: Color(0xFF2A1010))),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          14 + MediaQuery.of(context).padding.bottom,
        ),
        child: SizedBox(
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: style.buttonGradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: style.glow.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (selectedMethod == _PaymentMethod.wallet && !_walletSufficient)
                  ? null
                  : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: plan.tier == MechanicPriorityTier.premium
                    ? const Color(0xFF3D2200)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Xác nhận thanh toán',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Screen 2: Processing ─────────────────────────────────────────────────────

class _ProcessingScreen extends StatefulWidget {
  const _ProcessingScreen({super.key});

  @override
  State<_ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<_ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A1010), Color(0xFF2D0808)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Đang xử lý thanh toán',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng không tắt ứng dụng...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 3: Result ─────────────────────────────────────────────────────────

class _ResultScreen extends StatefulWidget {
  const _ResultScreen({
    super.key,
    required this.plan,
    required this.isSuccess,
    this.message,
    this.onRetry,
    required this.onDone,
  });

  final MechanicPriorityPlan plan;
  final bool isSuccess;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback onDone;

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.isSuccess;
    final iconColor = isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final glowColor = isSuccess
        ? const Color(0xFF22C55E).withValues(alpha: 0.3)
        : const Color(0xFFEF4444).withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      color: iconColor,
                      size: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  isSuccess ? 'Đăng ký thành công!' : 'Thanh toán thất bại',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  isSuccess
                      ? 'Bạn đã kích hoạt ${widget.plan.title} thành công.\nQuyền lợi có hiệu lực ngay lập tức.'
                      : (widget.message ??
                          'Không thể hoàn tất thanh toán.\nVui lòng kiểm tra lại số dư hoặc thử lại.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Detail card (chỉ hiện khi thành công)
              if (isSuccess)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1010),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Gói đã đăng ký',
                          value: widget.plan.title,
                          valueColor: const Color(0xFF22C55E),
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.attach_money_rounded,
                          label: 'Số tiền',
                          value: widget.plan.priceLabel,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Thời hạn',
                          value: widget.plan.periodLabel.replaceAll('/', '').trim(),
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Ngày kích hoạt',
                          value: _todayLabel(),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Buttons
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    if (!isSuccess && widget.onRetry != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Thử lại',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: widget.onDone,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isSuccess ? 'Xem gói của tôi' : 'Đóng',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accent is MaterialColor
                ? (accent as MaterialColor).shade400
                : accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.balance,
    required this.sufficient,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final int balance;
  final bool sufficient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWallet = method == _PaymentMethod.wallet;
    final borderColor = selected
        ? (sufficient ? AppColors.primary : const Color(0xFFEF4444))
        : const Color(0xFF3A1A1A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2A1010)
              : const Color(0xFF1A0808),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isWallet
                    ? Icons.account_balance_wallet_rounded
                    : Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWallet ? 'Ví SOSBIKE' : 'Chuyển khoản ngân hàng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWallet
                        ? 'Số dư: ${_fmt(balance)}đ'
                        : 'Sắp ra mắt',
                    style: TextStyle(
                      color: isWallet
                          ? (sufficient
                              ? const Color(0xFF22C55E)
                              : AppColors.primary)
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sufficient ? AppColors.primary : const Color(0xFFEF4444),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A2020)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.accent,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white.withValues(alpha: 0.55),
              fontSize: isTotal ? 13.5 : 12.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent ?? (isTotal ? Colors.white : Colors.white.withValues(alpha: 0.85)),
              fontSize: isTotal ? 14 : 12.5,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
