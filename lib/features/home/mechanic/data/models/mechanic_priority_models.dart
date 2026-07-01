import 'package:flutter/material.dart';

enum MechanicPriorityTier { free, standard, premium }

/// Thông tin gói thợ đang dùng (từ API).
class MechanicCurrentSubscription {
  const MechanicCurrentSubscription({
    required this.hasActivePlan,
    this.planId,
    this.planName = '',
    this.planTier = MechanicPriorityTier.free,
    this.price = 0,
    this.durationDays = 0,
    this.platformFeeRate,
    this.startDate,
    this.endDate,
    this.autoRenew,
    this.status,
    this.daysRemaining = 0,
  });

  final bool hasActivePlan;
  final int? planId;
  final String planName;
  final MechanicPriorityTier planTier;
  final double price;
  final int durationDays;
  final double? platformFeeRate;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? autoRenew;
  final String? status;
  final int daysRemaining;

  String get feeRateLabel => platformFeeRate != null
      ? '${(platformFeeRate! * 100).toStringAsFixed(0)}%'
      : '--';

  String get expiryLabel {
    if (endDate == null) return '--';
    final d = endDate!.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  factory MechanicCurrentSubscription.fromJson(Map<String, dynamic> json) {
    final tierStr = (json['planTier']?.toString() ?? 'FREE').toUpperCase();
    return MechanicCurrentSubscription(
      hasActivePlan: json['hasActivePlan'] == true,
      planId: (json['planId'] as num?)?.toInt(),
      planName: json['planName']?.toString() ?? '',
      planTier: tierStr == 'PREMIUM'
          ? MechanicPriorityTier.premium
          : tierStr == 'STANDARD'
              ? MechanicPriorityTier.standard
              : MechanicPriorityTier.free,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      platformFeeRate: (json['platformFeeRate'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      autoRenew: json['autoRenew'] as bool?,
      status: json['status']?.toString(),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  static MechanicCurrentSubscription get empty =>
      const MechanicCurrentSubscription(hasActivePlan: false);
}

class MechanicPriorityPlan {
  const MechanicPriorityPlan({
    this.planId,
    required this.tier,
    required this.title,
    required this.headerTitle,
    required this.priceLabel,
    required this.periodLabel,
    required this.benefits,
    required this.style,
    required this.showUpgradeButton,
    this.priceValue = 0,
  });

  final int? planId;
  final MechanicPriorityTier tier;
  final String title;
  final String headerTitle;
  final String priceLabel;
  final String periodLabel;
  final List<String> benefits;
  final MechanicPriorityPlanStyle style;
  final bool showUpgradeButton;
  /// Giá trị số (VND) dùng để kiểm tra số dư ví.
  final int priceValue;

  static const tierLabels = ['MIỄN PHÍ', 'PHỔ THÔNG', 'CAO CẤP'];

  static MechanicPriorityTier tierFromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'PREMIUM':
        return MechanicPriorityTier.premium;
      case 'STANDARD':
        return MechanicPriorityTier.standard;
      default:
        return MechanicPriorityTier.free;
    }
  }

  static String _formatVnd(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return value <= 0 ? 'Free 0 VND' : '${buf.toString()} VND';
  }

  factory MechanicPriorityPlan.fromApi(Map<String, dynamic> json) {
    final tier = tierFromCode(json['planTier']?.toString());
    final price = (json['price'] as num?)?.toInt() ?? 0;
    final days = (json['durationDays'] as num?)?.toInt() ?? 30;
    final benefitsJson = json['benefits'] as List<dynamic>?;
    final benefits = benefitsJson != null && benefitsJson.isNotEmpty
        ? benefitsJson
            .map((b) => (b as Map<String, dynamic>)['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : _defaultBenefits(tier, json['description']?.toString());

    return MechanicPriorityPlan(
      planId: (json['planId'] as num?)?.toInt(),
      tier: tier,
      title: tier == MechanicPriorityTier.free ? 'GÓI CƠ BẢN' : 'GÓI ƯU TIÊN',
      headerTitle: tier == MechanicPriorityTier.free ? 'Thành viên' : 'Thợ ưu tiên',
      priceLabel: _formatVnd(price),
      periodLabel: days >= 365 ? '/ Năm' : '/ Tháng',
      priceValue: price,
      benefits: benefits,
      style: _styleForTier(tier),
      showUpgradeButton: price > 0,
    );
  }

  static List<String> _defaultBenefits(MechanicPriorityTier tier, String? description) {
    if (description != null && description.trim().isNotEmpty) {
      return [description.trim()];
    }
    return switch (tier) {
      MechanicPriorityTier.premium => const [
          'Mọi quyền lợi gói phổ thông',
          'Phí sàn giảm còn 5%',
          'CRM chăm sóc khách ruột',
        ],
      MechanicPriorityTier.standard => const [
          'Nhận đơn sớm hơn 10–15 giây',
          'Phí sàn giảm còn 7%',
          'Tích xanh chứng nhận',
        ],
      MechanicPriorityTier.free => const [
          'Nhận đơn (tốc độ tiêu chuẩn)',
          'Phí sàn 10% cho mọi đơn',
        ],
    };
  }

  static MechanicPriorityPlanStyle _styleForTier(MechanicPriorityTier tier) => switch (tier) {
        MechanicPriorityTier.premium => MechanicPriorityPlanStyle.premium,
        MechanicPriorityTier.standard => MechanicPriorityPlanStyle.standard,
        MechanicPriorityTier.free => MechanicPriorityPlanStyle.free,
      };

  static List<MechanicPriorityPlan> sortByTier(List<MechanicPriorityPlan> items) {
    int order(MechanicPriorityTier t) => switch (t) {
          MechanicPriorityTier.free => 0,
          MechanicPriorityTier.standard => 1,
          MechanicPriorityTier.premium => 2,
        };
    return [...items]..sort((a, b) => order(a.tier).compareTo(order(b.tier)));
  }

  static List<MechanicPriorityPlan> get plans => const [
        MechanicPriorityPlan(
          tier: MechanicPriorityTier.free,
          title: 'GÓI CƠ BẢN (offline)',
          headerTitle: 'Thành viên',
          priceLabel: 'Free 0 VND',
          periodLabel: '/ Tháng',
          priceValue: 0,
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
          priceValue: 99000,
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
          priceValue: 899000,
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
