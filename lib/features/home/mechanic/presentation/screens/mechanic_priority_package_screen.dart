import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_priority_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_subscription_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_subscription_checkout_screen.dart';

/// Màn **Gói Ưu Tiên / Gói Cơ Bản** cho thợ.
class MechanicPriorityPackageScreen extends StatefulWidget {
  const MechanicPriorityPackageScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MechanicPriorityPackageScreen> createState() => _MechanicPriorityPackageScreenState();
}

class _MechanicPriorityPackageScreenState extends State<MechanicPriorityPackageScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.clamp(0, MechanicPriorityPlan.plans.length - 1);
    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: _currentPage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MechanicSubscriptionProvider>().load();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = MechanicPriorityPlan.plans;
    final activePlan = plans[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: activePlan.style.screenBackground,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                title: activePlan.headerTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 6),
              // --- Card gói đang dùng ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Consumer<MechanicSubscriptionProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading) {
                      return const _ActivePlanSkeleton();
                    }
                    return _ActivePlanCard(
                      subscription: prov.subscription,
                      onRefresh: () => prov.refresh(),
                    );
                  },
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: plans.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        var scale = 1.0;
                        if (_pageController.position.haveDimensions) {
                          final page = _pageController.page ?? _currentPage.toDouble();
                          scale = (1 - (page - index).abs() * 0.07).clamp(0.93, 1.0).toDouble();
                        }
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: _PriorityPlanCard(
                          plan: plan,
                          activeTierIndex: index,
                          onTierTap: _goToPage,
                          onUpgrade: plan.showUpgradeButton ? () => _showUpgradeDialog(context, plan) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              _PageDots(count: plans.length, activeIndex: _currentPage),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, MechanicPriorityPlan plan) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => MechanicSubscriptionCheckoutScreen(plan: plan),
        fullscreenDialog: true,
      ),
    );
    // Nếu đăng ký thành công, reload card gói đang dùng
    if (result == true && mounted) {
      context.read<MechanicSubscriptionProvider>().refresh();
    }
  }
}

// ─── Active Plan Card ─────────────────────────────────────────────────────────

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.subscription, required this.onRefresh});

  final MechanicCurrentSubscription subscription;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!subscription.hasActivePlan) {
      return _NoActivePlanBanner(onRefresh: onRefresh);
    }

    final Color cardBg;
    final Color accentColor;
    final IconData tierIcon;

    switch (subscription.planTier) {
      case MechanicPriorityTier.premium:
        cardBg = const Color(0xFF3D2000);
        accentColor = const Color(0xFFFFD95E);
        tierIcon = Icons.workspace_premium_rounded;
        break;
      case MechanicPriorityTier.standard:
        cardBg = const Color(0xFF3D0A0A);
        accentColor = const Color(0xFFFFB45B);
        tierIcon = Icons.star_rounded;
        break;
      case MechanicPriorityTier.free:
        cardBg = const Color(0xFF1C2730);
        accentColor = const Color(0xFF37BCE5);
        tierIcon = Icons.person_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.18),
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: Icon(tierIcon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'GÓI ĐANG DÙNG',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'ĐANG HOẠT ĐỘNG',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subscription.planName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh_rounded, color: accentColor, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: accentColor.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                icon: Icons.percent_rounded,
                label: 'Phí sàn',
                value: subscription.feeRateLabel,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              if (subscription.endDate != null) ...[
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Hết hạn',
                  value: subscription.expiryLabel,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
              ],
              _InfoChip(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Còn lại',
                value: subscription.daysRemaining > 0
                    ? '${subscription.daysRemaining} ngày'
                    : 'Không giới hạn',
                color: accentColor,
              ),
            ],
          ),
          if (subscription.autoRenew == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.autorenew_rounded, color: accentColor, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Tự động gia hạn đã bật',
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 10),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActivePlanBanner extends StatelessWidget {
  const _NoActivePlanBanner({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2530),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GÓI ĐANG DÙNG',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Gói Cơ Bản (Miễn Phí)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Phí sàn 10% · Nhận đơn tốc độ tiêu chuẩn',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.6), size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActivePlanSkeleton extends StatelessWidget {
  const _ActivePlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white60,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PriorityPlanCard extends StatelessWidget {
  const _PriorityPlanCard({
    required this.plan,
    required this.activeTierIndex,
    required this.onTierTap,
    required this.onUpgrade,
  });

  final MechanicPriorityPlan plan;
  final int activeTierIndex;
  final ValueChanged<int> onTierTap;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final style = plan.style;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.cardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.32),
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
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.28),
                    ],
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
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.24),
                      border: Border.all(color: style.accent, width: 1.6),
                    ),
                    child: Icon(Icons.workspace_premium_rounded, color: style.accent, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    plan.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TierPillsRow(
                    activeIndex: activeTierIndex,
                    activeColor: style.activeTierColor,
                    onTap: onTierTap,
                  ),
                  const SizedBox(height: 16),
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
                        Text(
                          plan.tier == MechanicPriorityTier.free
                              ? 'Gói cơ bản'
                              : 'Premium ${plan.periodLabel.contains('Năm') ? 'Annual' : 'Monthly'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                plan.priceLabel,
                                style: TextStyle(
                                  color: style.priceColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                plan.periodLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...plan.benefits.map(
                          (benefit) => _BenefitRow(text: benefit, color: style.accent),
                        ),
                      ],
                    ),
                  ),
                  if (onUpgrade != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: style.buttonGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: style.glow.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: plan.tier == MechanicPriorityTier.premium
                                ? const Color(0xFF3D2200)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đăng ký ngay!',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tier Pills ───────────────────────────────────────────────────────────────

class _TierPillsRow extends StatelessWidget {
  const _TierPillsRow({
    required this.activeIndex,
    required this.activeColor,
    required this.onTap,
  });

  final int activeIndex;
  final Color activeColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(MechanicPriorityPlan.tierLabels.length, (index) {
        final active = index == activeIndex;
        final label = MechanicPriorityPlan.tierLabels[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4, right: index == 2 ? 0 : 4),
            child: Material(
              color: active ? activeColor : Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Benefit Row ──────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text, required this.color});

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

// ─── Page Dots ────────────────────────────────────────────────────────────────

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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// ─── Card Pattern Painter ─────────────────────────────────────────────────────

class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter(this.style);

  final MechanicPriorityPlanStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.pattern.withValues(alpha: 0.22)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.square;

    for (double x = -size.height; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }

    if (style == MechanicPriorityPlanStyle.premium) {
      final beam = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            style.pattern.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(size.width * 0.18, 0, size.width * 0.08, size.height), beam);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.42, 0, size.width * 0.1, size.height), beam);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.68, 0, size.width * 0.08, size.height), beam);
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) => oldDelegate.style != style;
}
