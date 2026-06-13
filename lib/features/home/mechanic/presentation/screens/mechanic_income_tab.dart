import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_income_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_income_provider.dart';

/// Tab **Thu Nhập** — thống kê doanh thu thật từ API lịch sử đơn.
class MechanicIncomeTab extends StatefulWidget {
  const MechanicIncomeTab({super.key});

  @override
  State<MechanicIncomeTab> createState() => _MechanicIncomeTabState();
}

class _MechanicIncomeTabState extends State<MechanicIncomeTab> {
  static final _fmt = NumberFormat('#,##0', 'vi_VN');

  String _fmtMoney(int v) => '${_fmt.format(v)}đ';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicIncomeProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicIncomeProvider>();
    final income = provider.incomeData;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        children: [
          // ── Bộ lọc kỳ ──────────────────────────────────────────────
          _PeriodFilter(
            selected: provider.period,
            onChanged: (p) => context.read<MechanicIncomeProvider>().setPeriod(p),
          ),
          const SizedBox(height: 14),

          // ── Loading / Error / Data ──────────────────────────────────
          if (provider.isLoading)
            const _LoadingCard()
          else if (provider.errorMessage != null && provider.data == null)
            _ErrorCard(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            )
          else ...[
            // Tổng doanh thu
            _TotalRevenueCard(
              period: income.period,
              totalRevenue: _fmtMoney(income.totalRevenue),
              orderCount: income.orderCount,
              avgPerOrder: _fmtMoney(income.avgPerOrder),
              breakdown: income.breakdown,
            ),
            const SizedBox(height: 16),

            // Biểu đồ theo ngày
            _DailyChartSection(
              groups: income.dailyGroups,
              period: income.period,
              formatMoney: _fmtMoney,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Period Filter ────────────────────────────────────────────────────────────

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.selected, required this.onChanged});

  final IncomePeriod selected;
  final ValueChanged<IncomePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: IncomePeriod.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                p.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Loading Card ─────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            SizedBox(height: 12),
            Text(
              'Đang tải dữ liệu thu nhập...',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error Card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 36),
          const SizedBox(height: 8),
          const Text(
            'Không tải được dữ liệu',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Total Revenue Card ───────────────────────────────────────────────────────

class _TotalRevenueCard extends StatelessWidget {
  const _TotalRevenueCard({
    required this.period,
    required this.totalRevenue,
    required this.orderCount,
    required this.avgPerOrder,
    required this.breakdown,
  });

  final IncomePeriod period;
  final String totalRevenue;
  final int orderCount;
  final String avgPerOrder;
  final List<IncomeCategorySlice> breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng doanh thu ${period.label.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    totalRevenue,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16A34A),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          // Thống kê nhanh
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Số đơn',
                  value: '$orderCount đơn',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Trung bình/đơn',
                  value: avgPerOrder,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),

          if (orderCount > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // Pie chart + breakdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: _IncomePiePainter(breakdown),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        breakdown.map((slice) => _BreakdownRow(slice: slice)).toList(),
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

class _StatItem extends StatelessWidget {
  const _StatItem({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.slice});

  final IncomeCategorySlice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: slice.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              slice.label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563)),
            ),
          ),
          Text(
            '${slice.percent.toInt()}%',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Chart Section ──────────────────────────────────────────────────────

class _DailyChartSection extends StatelessWidget {
  const _DailyChartSection({
    required this.groups,
    required this.period,
    required this.formatMoney,
  });

  final List<DailyIncomeGroup> groups;
  final IncomePeriod period;
  final String Function(int) formatMoney;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu để vẽ biểu đồ',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      );
    }

    final maxVal =
        groups.fold<int>(0, (m, g) => g.total > m ? g.total : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Biểu đồ doanh thu${_chartTitle(period)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 196,
            child: _DailyBarChart(
              groups: groups,
              maxVal: maxVal,
              formatMoney: formatMoney,
              minSlotWidth: groups.length > 14 ? 44.0 : 0,
            ),
          ),
          if (groups.length > 14)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Vuốt ngang để xem đủ các ngày',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _chartTitle(IncomePeriod p) {
    switch (p) {
      case IncomePeriod.today:
        return ' hôm nay';
      case IncomePeriod.week:
        return ' theo ngày';
      case IncomePeriod.month:
        return ' theo ngày trong tháng';
    }
  }
}

class _DailyBarChart extends StatefulWidget {
  const _DailyBarChart({
    required this.groups,
    required this.maxVal,
    required this.formatMoney,
    this.minSlotWidth = 0,
  });

  final List<DailyIncomeGroup> groups;
  final int maxVal;
  final String Function(int) formatMoney;
  final double minSlotWidth;

  @override
  State<_DailyBarChart> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<_DailyBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final maxVal = widget.maxVal == 0 ? 1 : widget.maxVal;
    final useScroll = widget.minSlotWidth > 0;
    final chartWidth = useScroll
        ? widget.minSlotWidth * groups.length
        : double.infinity;

    Widget buildChart({double? width}) {
      final painter = _DailyBarPainter(
          groups: groups,
          maxVal: maxVal,
          selectedIndex: _selectedIndex,
          primaryColor: AppColors.primary,
        minSlotWidth: widget.minSlotWidth,
      );

      final interactive = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final slotW = useScroll
                ? widget.minSlotWidth
                : box.size.width / groups.length;
            final idx = (details.localPosition.dx / slotW)
                .floor()
                .clamp(0, groups.length - 1);
            setState(() => _selectedIndex = idx);

            final g = groups[idx];
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${g.dayLabel}: ${widget.formatMoney(g.total)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              ),
            );
          },
      );

      if (width == null) {
        return CustomPaint(painter: painter, child: interactive);
      }

      return CustomPaint(
        size: Size(width, 196),
        painter: painter,
        child: interactive,
      );
    }

    if (!useScroll) {
      return buildChart();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: SizedBox(
        width: chartWidth,
        height: 196,
        child: buildChart(width: chartWidth),
      ),
    );
  }
}

class _DailyBarPainter extends CustomPainter {
  _DailyBarPainter({
    required this.groups,
    required this.maxVal,
    required this.primaryColor,
    this.selectedIndex,
    this.minSlotWidth = 0,
  });

  final List<DailyIncomeGroup> groups;
  final int maxVal;
  final Color primaryColor;
  final int? selectedIndex;
  final double minSlotWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 8.0;
    const bottomPad = 34.0;
    const leftPad = 0.0;
    const rightPad = 0.0;
    final chartH = size.height - topPad - bottomPad;
    final chartW = size.width - leftPad - rightPad;

    if (groups.isEmpty) return;

    final slotW = minSlotWidth > 0 ? minSlotWidth : chartW / groups.length;
    const barW = 18.0;
    final labelStep = groups.length <= 10
        ? 1
        : math.max(1, (groups.length / 8).ceil());

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.8;
    for (var i = 0; i <= 4; i++) {
      final y = topPad + chartH * (1 - i / 4);
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final cx = leftPad + slotW * i + slotW / 2;
      final isSelected = i == selectedIndex;

      // Bar
      final heightRatio = group.total / maxVal;
      final barH = math.max(heightRatio * chartH, group.total > 0 ? 4.0 : 0.0);
      final barX = cx - barW / 2;
      final barY = topPad + chartH - barH;

      final barColor = isSelected
          ? primaryColor
          : (group.total > 0
              ? primaryColor.withValues(alpha: 0.6)
              : const Color(0xFFE5E7EB));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH),
          const Radius.circular(5),
        ),
        Paint()..color = barColor,
      );

      // Nhãn: luôn hiện ngày có doanh thu; thưa thêm khi > 10 cột
      final showLabel = isSelected ||
          i == 0 ||
          i == groups.length - 1 ||
          group.total > 0 ||
          (groups.length > 10 && i % labelStep == 0);
      if (showLabel) {
        _drawTextCentered(
          canvas,
          group.dayLabel,
          Offset(cx, size.height - bottomPad + 8),
          TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? primaryColor : const Color(0xFF9CA3AF),
          ),
        );
      }

      // Value label trên cột nếu > 0
      if (group.total > 0 && barH > 16) {
        final valStr = _shortMoney(group.total);
        _drawTextCentered(
          canvas,
          valStr,
          Offset(cx, barY - 12),
          TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? primaryColor : const Color(0xFF374151),
          ),
        );
      }
    }
  }

  String _shortMoney(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).round()}K';
    return '$v';
  }

  void _drawTextCentered(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final builder = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    builder.paint(
      canvas,
      Offset(center.dx - builder.width / 2, center.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _DailyBarPainter old) =>
      old.groups != groups ||
      old.maxVal != maxVal ||
      old.selectedIndex != selectedIndex;
}

// ─── Pie Painter (dùng lại) ──────────────────────────────────────────────────

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
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = slice.color,
      );
      start += sweep;
    }

    // Hole
    canvas.drawCircle(center, radius * 0.48, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _IncomePiePainter old) => old.slices != slices;
}
