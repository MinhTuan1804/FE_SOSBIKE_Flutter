import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/screens/customer_subscription_checkout_screen.dart';

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
    return Scaffold(
      backgroundColor: _membershipBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Đăng ký gói thành viên',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Consumer2<MembershipProvider, AuthProvider>(
        builder: (context, provider, auth, _) {
          final isCustomer = (auth.user?.userType ?? 'CUSTOMER').toUpperCase() == 'CUSTOMER';
          final target = isCustomer ? 'B2C' : 'DRIVER';
          final plans = provider.plans.where((plan) {
            return plan.targetAudience.toUpperCase() == target;
          }).toList();

          if (provider.isLoading && plans.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.errorMessage != null && plans.isEmpty) {
            return _ErrorState(message: provider.errorMessage!, onRetry: provider.load);
          }

          if (plans.isEmpty) {
            return _ErrorState(message: 'Chưa có gói thành viên nào.', onRetry: provider.load);
          }

          return Column(
            children: [
              const SizedBox(height: 6),
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
          );
        },
      ),
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

    // Luồng hiện tại chỉ hỗ trợ thanh toán chuyển khoản ngân hàng
    const paymentMethod = 'BANK_TRANSFER';

    final intent = await provider.createPaymentIntent(plan, paymentMethod: paymentMethod);
    if (!context.mounted) return;
    if (intent == null) {
      _showResult(context, false, provider.errorMessage ?? 'Không thể tạo giao dịch thanh toán.');
      return;
    }

    final session = PendingPaymentSession(
      planId: plan.planId,
      planName: plan.displayName,
      price: plan.price,
      autoRenew: _autoRenew,
      intent: intent,
      createdAt: DateTime.now(),
    );
    await provider.savePendingSession(session);

    if (!context.mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerSubscriptionCheckoutScreen(
          plan: plan,
          intent: intent,
          autoRenew: _autoRenew,
          createdAt: session.createdAt,
        ),
      ),
    );

    if (!context.mounted) return;
    if (ok == true) {
      _showResult(context, true, 'Đã đăng ký gói thành công.');
    }
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
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
        const SizedBox(width: 8),
        const Text(
          'Tự động gia hạn',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RestrictionText extends StatelessWidget {
  const _RestrictionText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFFAAAA), fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
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

class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter(this.style);
  final _PlanStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.pattern.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.15 + i * 0.25), size.height * 0.18),
        size.width * (0.18 + i * 0.04),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => false;
}

String _normalize(String value) {
  const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  const ascii = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
  var result = value;
  const length = vietnamese.length < ascii.length ? vietnamese.length : ascii.length;
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
