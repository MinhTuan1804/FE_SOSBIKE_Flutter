import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

const _membershipBackground = Color(0xFF141414);

class _MembershipScreenState extends State<MembershipScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.78);
  bool _loaded = false;
  bool _autoRenew = true;
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MembershipProvider>().load();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MembershipProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        final plans = provider.plans;
        final isCustomer = (auth.user?.userType ?? 'CUSTOMER').toUpperCase() == 'CUSTOMER';

        if (provider.isLoading && plans.isEmpty) {
          return const ColoredBox(
            color: _membershipBackground,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (provider.errorMessage != null && plans.isEmpty) {
          return ColoredBox(
            color: _membershipBackground,
            child: _ErrorState(message: provider.errorMessage!, onRetry: provider.load),
          );
        }

        if (plans.isEmpty) {
          return ColoredBox(
            color: _membershipBackground,
            child: _ErrorState(message: 'Chưa có gói thành viên nào.', onRetry: provider.load),
          );
        }

        return ColoredBox(
          color: _membershipBackground,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _CurrentPlanBar(
                subscription: provider.currentSubscription,
                onCancelRenewal: provider.isCancellingRenewal
                    ? null
                    : () => _cancelRenewal(context, provider),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: plans.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final style = _PlanStyle.fromPlan(plan);
                    final restriction = _restrictionText(provider, plan, isCustomer);
                    final canSubscribe = restriction == null && !provider.isSubscribing;

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        var scale = 1.0;
                        if (_pageController.position.haveDimensions) {
                          final page = _pageController.page ?? _currentPage.toDouble();
                          scale = (1 - (page - index).abs() * 0.08)
                              .clamp(0.92, 1.0)
                              .toDouble();
                        }

                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: _MembershipPlanCard(
                          plan: plan,
                          style: style,
                          autoRenew: _autoRenew,
                          isBusy: provider.isSubscribing,
                          restriction: restriction,
                          onAutoRenewChanged: plan.price <= 0 || plan.isCurrentPlan
                              ? null
                              : (value) => setState(() => _autoRenew = value),
                          onSubscribe: canSubscribe
                              ? () => _subscribe(context, provider, plan)
                              : null,
                          onCancelRenewal: plan.isCurrentPlan &&
                                  provider.currentSubscription?.autoRenew == true &&
                                  !provider.isCancellingRenewal
                              ? () => _cancelRenewal(context, provider)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              _PageDots(count: plans.length, activeIndex: _currentPage),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  String? _restrictionText(
    MembershipProvider provider,
    CustomerMembershipPlan plan,
    bool isCustomer,
  ) {
    if (!isCustomer && _PlanStyle.fromPlan(plan).kind == _PlanKind.driver) {
      return 'Chỉ tài khoản tài xế mới chọn được gói này.';
    }
    return provider.subscribeRestriction(plan);
  }

  Future<void> _subscribe(
    BuildContext context,
    MembershipProvider provider,
    CustomerMembershipPlan plan,
  ) async {
    if (plan.price <= 0) {
      final ok = await provider.subscribe(plan, autoRenew: false);
      if (!context.mounted) return;
      _showResult(context, ok, provider.errorMessage ?? 'Không thể đăng ký gói miễn phí.');
      return;
    }

    final paymentMethod = await _choosePaymentMethod(context);
    if (paymentMethod == null || !context.mounted) return;

    final intent = await provider.createPaymentIntent(plan, paymentMethod: paymentMethod);
    if (intent == null || !context.mounted) {
      _showResult(context, false, provider.errorMessage ?? 'Không thể tạo giao dịch thanh toán.');
      return;
    }

    final ok = await _showPaymentSheet(
      context,
      provider,
      plan,
      intent,
      autoRenew: _autoRenew,
    );

    if (!context.mounted) return;
    _showResult(
      context,
      ok,
      ok ? 'Đã đăng ký gói thành công.' : provider.errorMessage ?? 'Thanh toán thất bại.',
    );
  }

  Future<void> _cancelRenewal(BuildContext context, MembershipProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy tự gia hạn'),
        content: const Text('Gói hiện tại vẫn dùng đến ngày hết hạn. Bạn muốn hủy tự gia hạn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Hủy gia hạn'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    final result = await provider.cancelRenewal();
    if (!context.mounted) return;
    _showResult(
      context,
      result,
      result ? 'Đã hủy tự gia hạn.' : provider.errorMessage ?? 'Không thể hủy tự gia hạn.',
    );
  }

  void _showResult(BuildContext context, bool ok, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ),
    );
  }

  Future<String?> _choosePaymentMethod(BuildContext context) async {
    String selected = 'BANK_TRANSFER';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget option(String value, String label, IconData icon) {
              return RadioListTile<String>(
                value: value,
                groupValue: selected,
                onChanged: (value) => setDialogState(() => selected = value ?? selected),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: const Text('Chọn phương thức thanh toán'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  option('BANK_TRANSFER', 'Ngân hàng', Icons.account_balance),
                  option('MOMO', 'Momo', Icons.account_balance_wallet),
                  option('ZALOPAY', 'ZaloPay', Icons.payments_outlined),
                  option('VNPAY', 'VNPay', Icons.credit_card),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showPaymentSheet(
    BuildContext context,
    MembershipProvider provider,
    CustomerMembershipPlan plan,
    CustomerPaymentIntent intent, {
    required bool autoRenew,
  }) async {
    var isSubmitting = false;
    String? errorText;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.72,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                Future<void> copyText(String text, String message) async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                }

                Future<void> confirmPayment() async {
                  setSheetState(() {
                    isSubmitting = true;
                    errorText = null;
                  });

                  final ok = await provider.confirmPayment(
                    paymentId: intent.paymentId,
                    autoRenew: autoRenew,
                  );

                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(sheetContext, true);
                    return;
                  }

                  setSheetState(() {
                    isSubmitting = false;
                    errorText = provider.errorMessage ?? 'Không thể xác nhận thanh toán.';
                  });
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Thanh toán ${plan.displayName}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatMoney(intent.amount)} VND',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TransferDetailTile(
                          label: 'Phương thức',
                          value: _paymentMethodLabel(intent.paymentMethod),
                          onCopy: () => copyText(intent.paymentMethod, 'Đã sao chép phương thức.'),
                        ),
                        const SizedBox(height: 10),
                        _TransferDetailTile(
                          label: 'Nội dung chuyển khoản',
                          value: intent.qrContent ?? intent.paymentCode,
                          onCopy: () => copyText(
                            intent.qrContent ?? intent.paymentCode,
                            'Đã sao chép nội dung chuyển khoản.',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TransferDetailTile(
                          label: 'Mã giao dịch',
                          value: intent.paymentCode,
                          onCopy: () => copyText(intent.paymentCode, 'Đã sao chép mã giao dịch.'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 180,
                                height: 180,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    intent.qrContent ?? intent.paymentCode,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Quét mã hoặc chuyển khoản theo thông tin bên trên.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54, fontSize: 12.5, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            errorText!,
                            style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : confirmPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Xác nhận đã thanh toán',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    return result == true;
  }

  String _paymentMethodLabel(String paymentMethod) {
    return switch (paymentMethod.toUpperCase()) {
      'MOMO' => 'Momo',
      'ZALOPAY' => 'ZaloPay',
      'VNPAY' => 'VNPay',
      _ => 'Ngân hàng',
    };
  }
}

class _CurrentPlanBar extends StatelessWidget {
  const _CurrentPlanBar({
    required this.subscription,
    required this.onCancelRenewal,
  });

  final CustomerSubscription? subscription;
  final VoidCallback? onCancelRenewal;

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang dùng: ${subscription!.planName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
          if (subscription!.autoRenew)
            TextButton(
              onPressed: onCancelRenewal,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD2D2),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Hủy gia hạn'),
            )
          else
            Text(
              'Không tự gia hạn',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MembershipPlanCard extends StatelessWidget {
  const _MembershipPlanCard({
    required this.plan,
    required this.style,
    required this.autoRenew,
    required this.isBusy,
    required this.restriction,
    required this.onAutoRenewChanged,
    required this.onSubscribe,
    required this.onCancelRenewal,
  });

  final CustomerMembershipPlan plan;
  final _PlanStyle style;
  final bool autoRenew;
  final bool isBusy;
  final String? restriction;
  final ValueChanged<bool>? onAutoRenewChanged;
  final VoidCallback? onSubscribe;
  final VoidCallback? onCancelRenewal;

  @override
  Widget build(BuildContext context) {
    final benefits = plan.benefits.isEmpty
        ? <String>[if (plan.description?.trim().isNotEmpty == true) plan.description!.trim()]
        : plan.benefits.map((item) => item.displayName).toList();
    final price = plan.price <= 0 ? '0 VND' : '${_formatMoney(plan.price)} VND';
    final period = plan.price <= 0 ? '' : '/ ${plan.billingLabel}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.background,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CardPatternPainter(style))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.04), Colors.black.withValues(alpha: 0.26)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.24),
                        border: Border.all(color: style.accent, width: 1.6),
                      ),
                      child: Icon(style.icon, color: style.accent, size: 24),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      plan.displayName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152433).withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: style.accent.withValues(alpha: 0.45)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                plan.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (plan.isCurrentPlan) _SmallPill(text: 'Đang dùng', color: style.accent),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                price,
                                style: TextStyle(
                                  color: style.price,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (period.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  period,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: style.accent.withValues(alpha: 0.55), height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'CÁC QUYỀN LỢI BAO GỒM',
                          style: TextStyle(
                            color: style.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...benefits.take(6).map((benefit) => _BenefitRow(text: benefit, color: style.accent)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (onAutoRenewChanged != null)
                    _AutoRenewSwitch(
                      value: autoRenew,
                      color: style.accent,
                      onChanged: onAutoRenewChanged,
                    ),
                  if (restriction != null) ...[
                    if (onAutoRenewChanged != null) const SizedBox(height: 10),
                    _RestrictionText(text: restriction!),
                  ],
                  const SizedBox(height: 14),
                  if (onCancelRenewal != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onCancelRenewal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hủy tự gia hạn', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: style.button,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.16),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                plan.isCurrentPlan ? 'Đang sử dụng' : plan.price <= 0 ? 'Chọn gói miễn phí' : 'Nâng cấp ngay!',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoRenewSwitch extends StatelessWidget {
  const _AutoRenewSwitch({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final bool value;
  final Color color;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tự gia hạn',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: color.withValues(alpha: 0.55),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.4,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RestrictionText extends StatelessWidget {
  const _RestrictionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFD4D4),
          fontSize: 12.2,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _TransferDetailTile extends StatelessWidget {
  const _TransferDetailTile({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.black.withValues(alpha: 0.62), fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onCopy,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: const Text('Sao chép'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Thử lại', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter(this.style);

  final _PlanStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.pattern.withValues(alpha: 0.22)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.square;

    for (double x = -size.height; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }

    final roadPaint = Paint()..color = Colors.black.withValues(alpha: 0.14);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.33, 0, size.width * 0.11, size.height), roadPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.56, 0, size.width * 0.11, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) => oldDelegate.style != style;
}

enum _PlanKind { driver, free, standard, premium }

class _PlanStyle {
  const _PlanStyle({
    required this.kind,
    required this.background,
    required this.accent,
    required this.price,
    required this.button,
    required this.glow,
    required this.pattern,
    required this.icon,
  });

  final _PlanKind kind;
  final List<Color> background;
  final Color accent;
  final Color price;
  final Color button;
  final Color glow;
  final Color pattern;
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
        button: Color(0xFF16A34A),
        glow: Color(0xFF22C55E),
        pattern: Color(0xFF7BFF8F),
        icon: Icons.directions_bike_rounded,
      );
    }

    if (plan.price <= 0 || normalized.contains('CO BAN') || normalized.contains('FREE')) {
      return const _PlanStyle(
        kind: _PlanKind.free,
        background: [Color(0xFF3B3E42), Color(0xFF151719)],
        accent: Color(0xFF37BCE5),
        price: Color(0xFFFFFFFF),
        button: Color(0xFF0EA5E9),
        glow: Color(0xFF38BDF8),
        pattern: Color(0xFFC4CBD2),
        icon: Icons.workspace_premium_outlined,
      );
    }

    if (normalized.contains('CAO CAP') || plan.price >= 200000 || plan.durationDays >= 365) {
      return const _PlanStyle(
        kind: _PlanKind.premium,
        background: [Color(0xFF9C4E06), Color(0xFF2C1204)],
        accent: Color(0xFFFFD95E),
        price: Color(0xFFFFCB38),
        button: Color(0xFFE6A314),
        glow: Color(0xFFFFC934),
        pattern: Color(0xFFFFD76A),
        icon: Icons.workspace_premium_rounded,
      );
    }

    return const _PlanStyle(
      kind: _PlanKind.standard,
      background: [Color(0xFFA5140D), Color(0xFF330909)],
      accent: Color(0xFFFFB45B),
      price: Color(0xFFFFC23A),
      button: Color(0xFFF11116),
      glow: Color(0xFFFF402E),
      pattern: Color(0xFFFF3226),
      icon: Icons.workspace_premium_rounded,
    );
  }
}

String _normalize(String value) {
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
