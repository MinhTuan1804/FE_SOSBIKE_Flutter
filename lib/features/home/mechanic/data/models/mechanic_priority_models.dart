import 'package:flutter/material.dart';

enum MechanicPriorityTier { free, standard, premium }

class MechanicPriorityPlan {
  const MechanicPriorityPlan({
    required this.tier,
    required this.title,
    required this.headerTitle,
    required this.priceLabel,
    required this.periodLabel,
    required this.benefits,
    required this.style,
    required this.showUpgradeButton,
  });

  final MechanicPriorityTier tier;
  final String title;
  final String headerTitle;
  final String priceLabel;
  final String periodLabel;
  final List<String> benefits;
  final MechanicPriorityPlanStyle style;
  final bool showUpgradeButton;

  static const tierLabels = ['MIỄN PHÍ', 'PHỔ THÔNG', 'CAO CẤP'];

  static List<MechanicPriorityPlan> get plans => const [
        MechanicPriorityPlan(
          tier: MechanicPriorityTier.free,
          title: 'GÓI CƠ BẢN',
          headerTitle: 'Thành viên',
          priceLabel: 'Free 0 VND',
          periodLabel: '/ Tháng',
          benefits: [
            'Nhận đơn (Tốc độ tiêu chuẩn)',
            'Phí sàn 10% áp dụng cho tất cả đơn',
          ],
          style: MechanicPriorityPlanStyle.free,
          showUpgradeButton: false,
        ),
        MechanicPriorityPlan(
          tier: MechanicPriorityTier.standard,
          title: 'GÓI ƯU TIÊN',
          headerTitle: 'Thợ ưu tiên',
          priceLabel: '99,000 VND',
          periodLabel: '/ Tháng',
          benefits: [
            'Mọi quyền lợi của gói cơ bản',
            'Nhận được yêu cầu sửa xe sớm hơn 10-15s',
            'Phí sàn giảm còn 7%',
            'Có Tích xanh chứng nhận',
          ],
          style: MechanicPriorityPlanStyle.standard,
          showUpgradeButton: true,
        ),
        MechanicPriorityPlan(
          tier: MechanicPriorityTier.premium,
          title: 'GÓI ƯU TIÊN',
          headerTitle: 'Thợ ưu tiên',
          priceLabel: '899,000 VND',
          periodLabel: '/ Năm',
          benefits: [
            'Mọi quyền lợi của gói cơ bản và gói phổ thông',
            'Phí sàn giảm còn 5%',
            'Mở khóa toàn bộ CRM tự động chăm sóc khách ruột',
          ],
          style: MechanicPriorityPlanStyle.premium,
          showUpgradeButton: true,
        ),
      ];
}

class MechanicPriorityPlanStyle {
  const MechanicPriorityPlanStyle({
    required this.screenBackground,
    required this.cardGradient,
    required this.accent,
    required this.priceColor,
    required this.buttonGradient,
    required this.glow,
    required this.pattern,
    required this.activeTierColor,
  });

  final List<Color> screenBackground;
  final List<Color> cardGradient;
  final Color accent;
  final Color priceColor;
  final List<Color> buttonGradient;
  final Color glow;
  final Color pattern;
  final Color activeTierColor;

  static const free = MechanicPriorityPlanStyle(
    screenBackground: [Color(0xFF3A3D42), Color(0xFF151719)],
    cardGradient: [Color(0xFF4A4E54), Color(0xFF1C1F22)],
    accent: Color(0xFF37BCE5),
    priceColor: Colors.white,
    buttonGradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    glow: Color(0xFF38BDF8),
    pattern: Color(0xFFC4CBD2),
    activeTierColor: Color(0xFF2563EB),
  );

  static const standard = MechanicPriorityPlanStyle(
    screenBackground: [Color(0xFFB81818), Color(0xFF5C0A0A)],
    cardGradient: [Color(0xFFA5140D), Color(0xFF330909)],
    accent: Color(0xFFFFB45B),
    priceColor: Color(0xFFFFC23A),
    buttonGradient: [Color(0xFFF11116), Color(0xFFB80E12)],
    glow: Color(0xFFFF402E),
    pattern: Color(0xFFFF3226),
    activeTierColor: Color(0xFFE51F1F),
  );

  static const premium = MechanicPriorityPlanStyle(
    screenBackground: [Color(0xFF9C4E06), Color(0xFF2C1204)],
    cardGradient: [Color(0xFF8B4513), Color(0xFF2C1204)],
    accent: Color(0xFFFFD95E),
    priceColor: Color(0xFFFFCB38),
    buttonGradient: [Color(0xFFFFD95E), Color(0xFFE6A314)],
    glow: Color(0xFFFFC934),
    pattern: Color(0xFFFFD76A),
    activeTierColor: Color(0xFFFFD54F),
  );
}
