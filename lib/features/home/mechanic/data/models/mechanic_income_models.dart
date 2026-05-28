import 'package:flutter/material.dart';

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

class MechanicIncomeData {
  const MechanicIncomeData({
    required this.todayRevenue,
    required this.breakdown,
    required this.weeklyGroups,
  });

  final int todayRevenue;
  final List<IncomeCategorySlice> breakdown;
  final List<WeeklyIncomeGroup> weeklyGroups;

  static MechanicIncomeData fromTodayRevenue(int todayRevenue) {
    final total = todayRevenue > 0 ? todayRevenue : 500000;
    return MechanicIncomeData(
      todayRevenue: total,
      breakdown: const [
        IncomeCategorySlice(label: 'Tiền công', percent: 60, color: Color(0xFF7DD3FC)),
        IncomeCategorySlice(label: 'Phụ tùng', percent: 20, color: Color(0xFF3B82F6)),
        IncomeCategorySlice(label: 'Thưởng', percent: 20, color: Color(0xFF1D4ED8)),
      ],
      weeklyGroups: const [
        WeeklyIncomeGroup(weekLabel: 'Tuần 1', labor: 12, parts: 6, bonus: 4),
        WeeklyIncomeGroup(weekLabel: 'Tuần 2', labor: 16, parts: 8, bonus: 5),
        WeeklyIncomeGroup(weekLabel: 'Tuần 3', labor: 14, parts: 7, bonus: 6),
        WeeklyIncomeGroup(weekLabel: 'Tuần 4', labor: 20, parts: 9, bonus: 7),
        WeeklyIncomeGroup(weekLabel: 'Tuần 5', labor: 18, parts: 10, bonus: 8),
      ],
    );
  }
}
