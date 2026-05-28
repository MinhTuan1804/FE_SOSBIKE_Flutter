import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_income_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_dashboard_provider.dart';

/// Tab **Thu Nhập** trong Ví quản lí (Figma).
class MechanicIncomeTab extends StatefulWidget {
  const MechanicIncomeTab({super.key});

  @override
  State<MechanicIncomeTab> createState() => _MechanicIncomeTabState();
}

class _MechanicIncomeTabState extends State<MechanicIncomeTab> {
  static final _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicDashboardProvider>().load();
    });
  }

  String _formatCurrency(int amount) => '${_currencyFormat.format(amount)}đ';

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<MechanicDashboardProvider>().dashboard;
    final todayRevenue = dashboard?.todayRevenue.round() ?? 500000;
    final income = MechanicIncomeData.fromTodayRevenue(todayRevenue);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      children: [
        _TodayRevenueCard(
          amountLabel: _formatCurrency(income.todayRevenue),
          breakdown: income.breakdown,
        ),
        const SizedBox(height: 16),
        const Text(
          'Biểu đồ thu nhập',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        _WeeklyIncomeChart(groups: income.weeklyGroups),
      ],
    );
  }
}

class _TodayRevenueCard extends StatelessWidget {
  const _TodayRevenueCard({
    required this.amountLabel,
    required this.breakdown,
  });

  final String amountLabel;
  final List<IncomeCategorySlice> breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doanh thu hôm nay',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amountLabel,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF16A34A),
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 148,
            child: Column(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CustomPaint(
                    painter: _IncomePiePainter(breakdown),
                  ),
                ),
                const SizedBox(height: 8),
                ...breakdown.map(
                  (slice) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            slice.label,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                          ),
                        ),
                        Text(
                          '${slice.percent.toInt()}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomePiePainter extends CustomPainter {
  _IncomePiePainter(this.slices);

  final List<IncomeCategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    var start = -math.pi / 2;

    for (final slice in slices) {
      final sweep = 2 * math.pi * (slice.percent / 100);
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      start += sweep;
    }

    canvas.drawCircle(center, radius * 0.48, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _IncomePiePainter oldDelegate) => oldDelegate.slices != slices;
}

class _WeeklyIncomeChart extends StatelessWidget {
  const _WeeklyIncomeChart({required this.groups});

  final List<WeeklyIncomeGroup> groups;

  static const _laborColor = Color(0xFF7DD3FC);
  static const _partsColor = Color(0xFF3B82F6);
  static const _bonusColor = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _WeeklyBarPainter(groups: groups),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _ChartLegendDot(color: _laborColor, label: 'Tiền công'),
              SizedBox(width: 10),
              _ChartLegendDot(color: _partsColor, label: 'Phụ tùng'),
              SizedBox(width: 10),
              _ChartLegendDot(color: _bonusColor, label: 'Thưởng'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
      ],
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  _WeeklyBarPainter({required this.groups});

  final List<WeeklyIncomeGroup> groups;

  static const _laborColor = Color(0xFF7DD3FC);
  static const _partsColor = Color(0xFF3B82F6);
  static const _bonusColor = Color(0xFF1D4ED8);

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 8.0;
    const bottomPad = 28.0;
    const leftPad = 28.0;
    const rightPad = 8.0;
    final chartH = size.height - topPad - bottomPad;
    final chartW = size.width - leftPad - rightPad;
    const maxY = 25.0;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textStyle = const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600);

    for (var i = 0; i <= 5; i++) {
      final y = topPad + chartH * (1 - i / 5);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
      _drawText(canvas, '${i * 5}', Offset(4, y - 6), textStyle);
    }

    if (groups.isEmpty) return;

    final groupW = chartW / groups.length;
    const barW = 7.0;
    const gap = 2.0;

    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final cx = leftPad + groupW * i + groupW / 2;
      final values = [group.labor, group.parts, group.bonus];
      final colors = [_laborColor, _partsColor, _bonusColor];
      final totalBarW = barW * 3 + gap * 2;
      var x = cx - totalBarW / 2;

      for (var j = 0; j < values.length; j++) {
        final h = (values[j] / maxY) * chartH;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topPad + chartH - h, barW, h),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, Paint()..color = colors[j]);
        x += barW + gap;
      }

      _drawText(
        canvas,
        group.weekLabel,
        Offset(cx - 18, size.height - bottomPad + 6),
        const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final builder = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    builder.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) => oldDelegate.groups != groups;
}
