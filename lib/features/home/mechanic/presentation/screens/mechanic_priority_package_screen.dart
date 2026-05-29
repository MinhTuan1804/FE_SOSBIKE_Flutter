import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_priority_models.dart';

/// Màn **Gói Ưu Tiên / Gói Cơ Bản** cho thợ (Figma).
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
                          onUpgrade: plan.showUpgradeButton ? () => _showUpgradeSnack(context, plan) : null,
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

  void _showUpgradeSnack(BuildContext context, MechanicPriorityPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nâng cấp ${plan.title} — tính năng thanh toán đang hoàn thiện.')),
    );
  }
}

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
                          plan.tier == MechanicPriorityTier.free ? 'Gói cơ bản' : 'Premium ${plan.periodLabel.contains('Năm') ? 'Annual' : 'Monthly'}',
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Nâng cấp ngay!',
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
