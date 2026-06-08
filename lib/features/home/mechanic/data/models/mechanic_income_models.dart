import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_customer_history_entry.dart';

/// Slice trong biểu đồ tròn thu nhập.
class IncomeCategorySlice {
  const IncomeCategorySlice({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;
}

/// Nhóm dữ liệu 1 ngày cho biểu đồ cột.
class DailyIncomeGroup {
  const DailyIncomeGroup({
    required this.dayLabel,
    required this.date,
    required this.total,
  });

  final String dayLabel;
  final DateTime date;
  final int total;
}

/// Nhóm dữ liệu 1 tuần cho biểu đồ cột (legacy — giữ lại cho chart cũ).
class WeeklyIncomeGroup {
  const WeeklyIncomeGroup({
    required this.weekLabel,
    required this.labor,
    required this.parts,
    required this.bonus,
  });

  final String weekLabel;
  final double labor;
  final double parts;
  final double bonus;
}

/// Enum kỳ thống kê.
enum IncomePeriod { today, week, month }

extension IncomePeriodLabel on IncomePeriod {
  String get label {
    switch (this) {
      case IncomePeriod.today:
        return 'Hôm nay';
      case IncomePeriod.week:
        return 'Tuần này';
      case IncomePeriod.month:
        return 'Tháng này';
    }
  }

  DateTimeRange get range {
    final now = DateTime.now();
    switch (this) {
      case IncomePeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case IncomePeriod.week:
        final weekday = now.weekday; // 1=Mon..7=Sun
        final start = DateTime(now.year, now.month, now.day - (weekday - 1));
        return DateTimeRange(start: start, end: now);
      case IncomePeriod.month:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
    }
  }
}

/// Model tổng hợp cho tab Thu Nhập, tính từ danh sách đơn thật.
class MechanicIncomeData {
  const MechanicIncomeData({
    required this.period,
    required this.totalRevenue,
    required this.orderCount,
    required this.avgPerOrder,
    required this.breakdown,
    required this.dailyGroups,
    required this.weeklyGroups,
  });

  final IncomePeriod period;
  final int totalRevenue;
  final int orderCount;
  final int avgPerOrder;
  final List<IncomeCategorySlice> breakdown;
  final List<DailyIncomeGroup> dailyGroups;
  final List<WeeklyIncomeGroup> weeklyGroups; // dùng cho chart cũ

  /// Tính từ danh sách đơn thật trả về từ API.
  factory MechanicIncomeData.fromOrders(
    List<MechanicCustomerHistoryEntry> orders,
    IncomePeriod period,
  ) {
    // Lọc đơn theo kỳ
    final range = period.range;
    final filtered = orders.where((o) {
      return !o.completedAt.isBefore(range.start) &&
          !o.completedAt.isAfter(range.end);
    }).toList();

    final total = filtered.fold<int>(0, (sum, o) => sum + o.totalAmount);
    final count = filtered.length;
    final avg = count > 0 ? (total / count).round() : 0;

    // Tạo daily groups (7 ngày gần nhất hoặc theo kỳ)
    final dailyGroups = _buildDailyGroups(filtered, period);

    // Breakdown tỷ lệ (tạm thời chia 70% công sức / 20% phụ tùng / 10% phí)
    final breakdown = total > 0
        ? [
            const IncomeCategorySlice(
                label: 'Tiền công',
                percent: 70,
                color: Color(0xFF16A34A)),
            const IncomeCategorySlice(
                label: 'Phụ tùng',
                percent: 20,
                color: Color(0xFF3B82F6)),
            const IncomeCategorySlice(
                label: 'Phí dịch vụ',
                percent: 10,
                color: Color(0xFFF59E0B)),
          ]
        : [
            const IncomeCategorySlice(
                label: 'Chưa có đơn',
                percent: 100,
                color: Color(0xFFE5E7EB)),
          ];

    // Weekly groups cho chart cũ — map từ daily
    final weeklyGroups = _buildWeeklyGroups(filtered);

    return MechanicIncomeData(
      period: period,
      totalRevenue: total,
      orderCount: count,
      avgPerOrder: avg,
      breakdown: breakdown,
      dailyGroups: dailyGroups,
      weeklyGroups: weeklyGroups,
    );
  }

  static List<DailyIncomeGroup> _buildDailyGroups(
    List<MechanicCustomerHistoryEntry> orders,
    IncomePeriod period,
  ) {
    final now = DateTime.now();

    // Tạo map date → total
    final map = <String, int>{};
    for (final o in orders) {
      final key =
          '${o.completedAt.year}-${o.completedAt.month.toString().padLeft(2, '0')}-${o.completedAt.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + o.totalAmount;
    }

    final dates = <DateTime>[];
    switch (period) {
      case IncomePeriod.today:
        dates.add(DateTime(now.year, now.month, now.day));
        break;
      case IncomePeriod.week:
        final weekday = now.weekday; // 1=Mon..7=Sun
        final monday = DateTime(now.year, now.month, now.day - (weekday - 1));
        for (var i = 0; i < 7; i++) {
          dates.add(DateTime(monday.year, monday.month, monday.day + i));
        }
        break;
      case IncomePeriod.month:
        // Từ ngày 1 của tháng hiện tại → hôm nay (khớp "trong tháng")
        for (var day = 1; day <= now.day; day++) {
          dates.add(DateTime(now.year, now.month, day));
        }
        break;
    }

    return dates.map((date) {
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final total = map[key] ?? 0;
      final label = period == IncomePeriod.today
          ? 'Hôm nay'
          : period == IncomePeriod.month
              ? '${date.day}/${date.month}'
              : _weekdayLabel(date.weekday);
      return DailyIncomeGroup(dayLabel: label, date: date, total: total);
    }).toList();
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  static List<WeeklyIncomeGroup> _buildWeeklyGroups(
      List<MechanicCustomerHistoryEntry> orders) {
    // Nhóm theo tuần trong tháng
    final weekMap = <int, int>{};
    for (final o in orders) {
      final week = ((o.completedAt.day - 1) ~/ 7) + 1;
      weekMap[week] = (weekMap[week] ?? 0) + o.totalAmount;
    }

    return List.generate(4, (i) {
      final week = i + 1;
      final total = weekMap[week] ?? 0;
      final inMillions = total / 1000000;
      return WeeklyIncomeGroup(
        weekLabel: 'Tuần $week',
        labor: inMillions * 0.7,
        parts: inMillions * 0.2,
        bonus: inMillions * 0.1,
      );
    });
  }

  /// Fallback khi chưa có data
  static MechanicIncomeData empty(IncomePeriod period) => MechanicIncomeData(
        period: period,
        totalRevenue: 0,
        orderCount: 0,
        avgPerOrder: 0,
        breakdown: const [
          IncomeCategorySlice(
              label: 'Chưa có đơn', percent: 100, color: Color(0xFFE5E7EB)),
        ],
        dailyGroups: const [],
        weeklyGroups: const [],
      );
}

class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}
