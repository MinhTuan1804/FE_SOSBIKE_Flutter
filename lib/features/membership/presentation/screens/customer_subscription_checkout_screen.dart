import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum _CheckoutStep { confirm, payOS, processing, success, failure }

class CustomerSubscriptionCheckoutScreen extends StatefulWidget {
  const CustomerSubscriptionCheckoutScreen({
    super.key,
    required this.plan,
    required this.intent,
    required this.autoRenew,
    this.createdAt,
  });

  final CustomerMembershipPlan plan;
  final CustomerPaymentIntent intent;
  final bool autoRenew;
  final DateTime? createdAt;

  @override
  State<CustomerSubscriptionCheckoutScreen> createState() =>
      _CustomerSubscriptionCheckoutScreenState();
}

class _CustomerSubscriptionCheckoutScreenState
    extends State<CustomerSubscriptionCheckoutScreen> {
  _CheckoutStep _step = _CheckoutStep.confirm;
  late final DateTime _expiryTime;
  Timer? _timer;
  Duration _timeRemaining = const Duration(minutes: 15);
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _expiryTime = (widget.createdAt ?? DateTime.now()).add(const Duration(minutes: 15));
    _updateTimeRemaining();
    if (!_isExpired) {
      _startTimer();
    } else {
      // Đã hết hạn ngay khi khởi tạo -> xóa session ngay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MembershipProvider>().clearPendingSession();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final diff = _expiryTime.difference(DateTime.now());
    if (diff.isNegative || diff == Duration.zero) {
      _timeRemaining = Duration.zero;
      if (!_isExpired) {
        _isExpired = true;
        _timer?.cancel();
        // Tự động dọn dẹp session khi countdown về 0
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<MembershipProvider>().clearPendingSession();
          }
        });
      }
    } else {
      _timeRemaining = diff;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _confirmPayment() async {
    if (_isExpired) return;

    setState(() => _step = _CheckoutStep.processing);

    final provider = context.read<MembershipProvider>();
    final ok = await provider.confirmPayment(
      paymentId: widget.intent.paymentId,
      autoRenew: widget.autoRenew,
    );

    if (mounted) {
      setState(() {
        _step = ok ? _CheckoutStep.success : _CheckoutStep.failure;
      });
    }
  }

  // Helper để dọn dẹp session khi người dùng thoát màn hình đã hết hạn
  Future<void> _handlePop() async {
    if (_isExpired && mounted) {
      final provider = Provider.of<MembershipProvider>(context, listen: false);
      await provider.clearPendingSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_step == _CheckoutStep.processing) return false;
        final navigator = Navigator.of(context);
        await _handlePop();
        if (_step == _CheckoutStep.success || _step == _CheckoutStep.failure) {
          navigator.pop(_step == _CheckoutStep.success);
          return false;
        }
        return true;
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: switch (_step) {
          _CheckoutStep.confirm => _ConfirmView(
              key: const ValueKey('confirm'),
              plan: widget.plan,
              intent: widget.intent,
              autoRenew: widget.autoRenew,
              onBack: () => Navigator.of(context).pop(false),
              onConfirm: () => setState(() => _step = _CheckoutStep.payOS),
            ),
          _CheckoutStep.payOS => _PayOSQRView(
              key: const ValueKey('payOS'),
              plan: widget.plan,
              intent: widget.intent,
              autoRenew: widget.autoRenew,
              timeRemaining: _timeRemaining,
              isExpired: _isExpired,
              formattedTime: _formatDuration(_timeRemaining),
              onBack: () async {
                await _handlePop();
                if (mounted) {
                  setState(() => _step = _CheckoutStep.confirm);
                }
              },
              onConfirm: _confirmPayment,
            ),
          _CheckoutStep.processing => const _ProcessingView(
              key: ValueKey('processing'),
            ),
          _CheckoutStep.success => _ResultView(
              key: const ValueKey('success'),
              plan: widget.plan,
              intent: widget.intent,
              isSuccess: true,
              onDone: () async {
                final navigator = Navigator.of(context);
                await _handlePop();
                navigator.pop(true);
              },
            ),
          _CheckoutStep.failure => _ResultView(
              key: const ValueKey('failure'),
              plan: widget.plan,
              intent: widget.intent,
              isSuccess: false,
              onRetry: () => setState(() => _step = _CheckoutStep.confirm),
              onDone: () async {
                final navigator = Navigator.of(context);
                await _handlePop();
                navigator.pop(false);
              },
            ),
        },
      ),
    );
  }
}

// ─── Step 1: Confirm (Đồng bộ thiết kế giống Thợ) ──────────────────────────

class _ConfirmView extends StatelessWidget {
  const _ConfirmView({
    super.key,
    required this.plan,
    required this.intent,
    required this.autoRenew,
    required this.onBack,
    required this.onConfirm,
  });

  final CustomerMembershipPlan plan;
  final CustomerPaymentIntent intent;
  final bool autoRenew;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  String _formatMoney(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      final remaining = number.length - i;
      buffer.write(number[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final style = _PlanStyle.fromPlan(plan);
    final benefits = plan.benefits.isEmpty
        ? <String>[if (plan.description?.trim().isNotEmpty == true) plan.description!.trim()]
        : plan.benefits.map((item) => item.displayName).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: Column(
        children: [
          // ── Header gradient giống thợ ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: style.background,
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
                        color: Colors.black.withValues(alpha: 0.35),
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
                              style.icon,
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
                                  plan.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  autoRenew ? 'Gia hạn: Tự động' : 'Gia hạn: Không tự động',
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
                                '${_formatMoney(intent.amount)}đ',
                                style: TextStyle(
                                  color: style.price,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '/ ${plan.billingLabel}',
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
              physics: const BouncingScrollPhysics(),
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
                      children: benefits
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
                    label: 'Chuyển khoản ngân hàng (PayOS)',
                    subLabel: 'Mã QR & Chuyển khoản nhanh',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),

                  // Order summary
                  const _SectionTitle(label: 'Tóm tắt đơn hàng', accent: Colors.white),
                  const SizedBox(height: 10),
                  _OrderSummaryRow(label: 'Gói', value: plan.displayName),
                  _OrderSummaryRow(
                    label: 'Thời hạn',
                    value: plan.billingLabel,
                  ),
                  _OrderSummaryRow(label: 'Giá gốc', value: '${_formatMoney(plan.price)}đ'),
                  _OrderSummaryRow(label: 'Giảm giá', value: '0đ'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFF3A1A1A)),
                  ),
                  _OrderSummaryRow(
                    label: 'Tổng thanh toán',
                    value: '${_formatMoney(intent.amount)}đ',
                    isTotal: true,
                    accent: style.price,
                  ),
                  const SizedBox(height: 60),
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
              gradient: LinearGradient(colors: [AppColors.primary, const Color(0xFFB81818)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Tiếp tục thanh toán',
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

// ─── Step 2: PayOS QR View (Giao diện hiển thị QR) ──────────────────────────

class _PayOSQRView extends StatelessWidget {
  const _PayOSQRView({
    super.key,
    required this.plan,
    required this.intent,
    required this.autoRenew,
    required this.timeRemaining,
    required this.isExpired,
    required this.formattedTime,
    required this.onBack,
    required this.onConfirm,
  });

  final CustomerMembershipPlan plan;
  final CustomerPaymentIntent intent;
  final bool autoRenew;
  final Duration timeRemaining;
  final bool isExpired;
  final String formattedTime;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  Future<void> _copyText(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatMoney(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      final remaining = number.length - i;
      buffer.write(number[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Sửa hiển thị nội dung chuyển khoản thành SOSBIKE paymentCode
    final bankContent = 'SOSBIKE ${intent.paymentCode}';

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Thanh toán gói',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Countdown Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isExpired
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isExpired ? Icons.error_outline_rounded : Icons.hourglass_bottom_rounded,
                    color: isExpired ? const Color(0xFFEF4444) : AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isExpired
                        ? 'Giao dịch đã hết hạn thanh toán'
                        : 'Thời gian thanh toán còn lại: ',
                    style: TextStyle(
                      color: isExpired ? const Color(0xFFFCA5A5) : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isExpired)
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Plan Info Summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gia hạn: ${autoRenew ? "Bật tự động" : "Không tự động"}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_formatMoney(intent.amount)}đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '/ ${plan.billingLabel}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Info & QR
                    const Text(
                      'Thông tin chuyển khoản',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          // QR Code
                          Container(
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: intent.qrContent != null && intent.qrContent!.trim().isNotEmpty
                                ? Image.network(
                                    'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(intent.qrContent!)}',
                                    width: 160,
                                    height: 160,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.black45),
                                            SizedBox(height: 6),
                                            Text(
                                              'Không tải được QR',
                                              style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(color: AppColors.primary),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      intent.paymentCode,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Quét mã QR bằng ứng dụng Ngân hàng để thanh toán nhanh chóng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (intent.checkoutUrl != null && intent.checkoutUrl!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: OutlinedButton.icon(
                                onPressed: isExpired
                                    ? null
                                    : () async {
                                        final Uri url = Uri.parse(intent.checkoutUrl!);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                                label: const Text(
                                  'Mở link thanh toán PayOS',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bank Detail Fields
                    _InfoRow(
                      label: 'Số tiền cần chuyển',
                      value: '${_formatMoney(intent.amount)}đ',
                      onCopy: () => _copyText(context, intent.amount.round().toString(), 'Đã sao chép số tiền.'),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Nội dung chuyển khoản',
                      value: bankContent,
                      onCopy: () => _copyText(context, bankContent, 'Đã sao chép nội dung chuyển khoản.'),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Mã giao dịch',
                      value: intent.paymentCode,
                      onCopy: () => _copyText(context, intent.paymentCode, 'Đã sao chép mã giao dịch.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isExpired ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 16),
                SizedBox(width: 8),
                Text(
                  'Xác nhận đã thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCopy,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sao chép', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Processing ───────────────────────────────────────────────────

class _ProcessingView extends StatefulWidget {
  const _ProcessingView({super.key});

  @override
  State<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<_ProcessingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
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
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang xác thực giao dịch',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Vui lòng giữ ứng dụng mở...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 4: Result ─────────────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  const _ResultView({
    super.key,
    required this.plan,
    required this.intent,
    required this.isSuccess,
    this.onRetry,
    required this.onDone,
  });

  final CustomerMembershipPlan plan;
  final CustomerPaymentIntent intent;
  final bool isSuccess;
  final VoidCallback? onRetry;
  final VoidCallback onDone;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatMoney(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      final remaining = number.length - i;
      buffer.write(number[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.isSuccess;
    final iconColor = isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final glowColor = isSuccess
        ? const Color(0xFF22C55E).withValues(alpha: 0.25)
        : const Color(0xFFEF4444).withValues(alpha: 0.25);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(color: glowColor, blurRadius: 26, spreadRadius: 4),
                      ],
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                      color: iconColor,
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  isSuccess ? 'Đăng ký thành công!' : 'Xác thực thất bại',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  isSuccess
                      ? 'Bạn đã kích hoạt gói ${widget.plan.displayName} thành công.\nQuyền lợi sẽ hoạt động ngay lập tức.'
                      : 'Không tìm thấy thông tin chuyển khoản tương ứng.\nVui lòng kiểm tra lại giao dịch của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Detail Cards
              if (isSuccess)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        _ResultDetailRow(label: 'Gói đăng ký', value: widget.plan.displayName, valueColor: const Color(0xFF22C55E)),
                        const SizedBox(height: 10),
                        _ResultDetailRow(label: 'Số tiền thanh toán', value: '${_formatMoney(widget.intent.amount)}đ'),
                        const SizedBox(height: 10),
                        _ResultDetailRow(label: 'Chu kỳ thanh toán', value: widget.plan.billingLabel),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    if (!isSuccess && widget.onRetry != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: widget.onDone,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isSuccess ? 'Xem gói của tôi' : 'Đóng',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
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
}

class _ResultDetailRow extends StatelessWidget {
  const _ResultDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Sub widgets & style class ──────────────────────────────────────────────

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
            color: accent,
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
    required this.label,
    required this.subLabel,
    required this.onTap,
  });

  final String label;
  final String subLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1010),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
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
              child: const Icon(
                Icons.account_balance_rounded,
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
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
            )
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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

enum _PlanKind { free, standard, premium, driver }

class _PlanStyle {
  const _PlanStyle({
    required this.kind,
    required this.background,
    required this.accent,
    required this.price,
    required this.icon,
  });

  final _PlanKind kind;
  final List<Color> background;
  final Color accent;
  final Color price;
  final IconData icon;

  static _PlanStyle fromPlan(CustomerMembershipPlan plan) {
    final normalized = _normalize(plan.displayName);
    if (normalized.contains('TAI XE') ||
        (plan.price >= 100000 && plan.price < 250000 && plan.durationDays >= 365)) {
      return const _PlanStyle(
        kind: _PlanKind.driver,
        background: [Color(0xFF0EA323), Color(0xFF08340B)],
        accent: Color(0xFF35E956),
        price: Color(0xFFFFFFFF),
        icon: Icons.directions_bike_rounded,
      );
    }

    if (plan.price <= 0 || normalized.contains('CO BAN') || normalized.contains('FREE')) {
      return const _PlanStyle(
        kind: _PlanKind.free,
        background: [Color(0xFF3B3E42), Color(0xFF151719)],
        accent: Color(0xFF37BCE5),
        price: Color(0xFFFFFFFF),
        icon: Icons.workspace_premium_outlined,
      );
    }

    if (normalized.contains('CAO CAP') || plan.price >= 200000 || plan.durationDays >= 365) {
      return const _PlanStyle(
        kind: _PlanKind.premium,
        background: [Color(0xFF9C4E06), Color(0xFF2C1204)],
        accent: Color(0xFFFFD95E),
        price: Color(0xFFFFCB38),
        icon: Icons.workspace_premium_rounded,
      );
    }

    return const _PlanStyle(
      kind: _PlanKind.standard,
      background: [Color(0xFFA5140D), Color(0xFF330909)],
      accent: Color(0xFFFFB45B),
      price: Color(0xFFFFC23A),
      icon: Icons.workspace_premium_rounded,
    );
  }

  static String _normalize(String value) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const ascii = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    var result = value;
    final length = vietnamese.length < ascii.length ? vietnamese.length : ascii.length;
    for (var i = 0; i < length; i++) {
      result = result.replaceAll(vietnamese[i], ascii[i]);
    }
    return result.toUpperCase();
  }
}
