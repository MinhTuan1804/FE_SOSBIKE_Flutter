class MembershipBenefit {
  const MembershipBenefit({
    required this.benefitId,
    required this.code,
    required this.name,
    this.description,
    this.value,
    this.usageLimit,
  });

  final int benefitId;
  final String code;
  final String name;
  final String? description;
  final double? value;
  final int? usageLimit;

  factory MembershipBenefit.fromJson(Map<String, dynamic> json) {
    return MembershipBenefit(
      benefitId: _asInt(json['benefitId']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      value: _asDoubleOrNull(json['value']),
      usageLimit: _asIntOrNull(json['usageLimit']),
    );
  }

  String get displayName => name.trim().isEmpty ? 'Quyền lợi thành viên' : name.trim();
}

class CustomerMembershipPlan {
  const CustomerMembershipPlan({
    required this.planId,
    required this.name,
    required this.targetAudience,
    required this.price,
    required this.durationDays,
    required this.billingCycle,
    this.description,
    required this.isFree,
    required this.isCurrentPlan,
    required this.benefits,
  });

  final int planId;
  final String name;
  final String targetAudience;
  final double price;
  final int durationDays;
  final String billingCycle;
  final String? description;
  final bool isFree;
  final bool isCurrentPlan;
  final List<MembershipBenefit> benefits;

  factory CustomerMembershipPlan.fromJson(Map<String, dynamic> json) {
    final benefitsRaw = json['benefits'];
    return CustomerMembershipPlan(
      planId: _asInt(json['planId']),
      name: json['name']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? '',
      price: _asDouble(json['price']),
      durationDays: _asInt(json['durationDays']),
      billingCycle: json['billingCycle']?.toString() ?? '',
      description: json['description']?.toString(),
      isFree: json['isFree'] == true,
      isCurrentPlan: json['isCurrentPlan'] == true,
      benefits: benefitsRaw is List
          ? benefitsRaw
              .whereType<Map>()
              .map((item) => MembershipBenefit.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  String get billingLabel {
    if (price <= 0) return 'Miễn phí';
    if (billingCycle.toUpperCase() == 'YEAR' || durationDays >= 365) return 'Năm';
    return 'Tháng';
  }

  int get rank {
    if (price >= 250000) return 3;
    if (price >= 100000) return 2;
    if (price > 0) return 1;
    return 0;
  }

  String get displayName {
    return name.trim().isEmpty ? 'Gói Thành Viên' : name.trim();
  }
}

class CustomerSubscription {
  const CustomerSubscription({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.price,
    this.startDate,
    required this.endDate,
    required this.status,
    required this.autoRenew,
    this.paymentId,
    required this.benefits,
  });

  final String subscriptionId;
  final int planId;
  final String planName;
  final double price;
  final DateTime? startDate;
  final DateTime endDate;
  final String status;
  final bool autoRenew;
  final String? paymentId;
  final List<MembershipBenefit> benefits;

  factory CustomerSubscription.fromJson(Map<String, dynamic> json) {
    final benefitsRaw = json['benefits'];
    return CustomerSubscription(
      subscriptionId: json['subscriptionId']?.toString() ?? '',
      planId: _asInt(json['planId']),
      planName: json['planName']?.toString() ?? '',
      price: _asDouble(json['price']),
      startDate: _asDateOrNull(json['startDate']),
      endDate: _asDateOrNull(json['endDate']) ?? DateTime.now(),
      status: json['status']?.toString() ?? '',
      autoRenew: json['autoRenew'] == true,
      paymentId: json['paymentId']?.toString(),
      benefits: benefitsRaw is List
          ? benefitsRaw
              .whereType<Map>()
              .map((item) => MembershipBenefit.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}

class CustomerPaymentIntent {
  const CustomerPaymentIntent({
    required this.paymentId,
    required this.paymentCode,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    this.qrContent,
    this.checkoutUrl,
    this.expiredAt,
    this.transactionDate,
  });

  final String paymentId;
  final String paymentCode;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String? qrContent;
  final String? checkoutUrl;
  final DateTime? expiredAt;
  final DateTime? transactionDate;

  factory CustomerPaymentIntent.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentIntent(
      paymentId: json['paymentId']?.toString() ?? '',
      paymentCode: json['paymentCode']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentType: json['paymentType']?.toString() ?? '',
      qrContent: json['qrContent']?.toString(),
      checkoutUrl: json['checkoutUrl']?.toString(),
      expiredAt: _asDateOrNull(json['expiredAt']),
      transactionDate: _asDateOrNull(json['transactionDate']),
    );
  }
}

int _asInt(dynamic value) => _asIntOrNull(value) ?? 0;

int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _asDouble(dynamic value) => _asDoubleOrNull(value) ?? 0;

double? _asDoubleOrNull(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _asDateOrNull(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class PendingPaymentSession {
  final int planId;
  final String planName;
  final double price;
  final bool autoRenew;
  final CustomerPaymentIntent intent;
  final DateTime createdAt;

  PendingPaymentSession({
    required this.planId,
    required this.planName,
    required this.price,
    required this.autoRenew,
    required this.intent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'planName': planName,
        'price': price,
        'autoRenew': autoRenew,
        'intent': {
          'paymentId': intent.paymentId,
          'paymentCode': intent.paymentCode,
          'amount': intent.amount,
          'paymentMethod': intent.paymentMethod,
          'paymentType': intent.paymentType,
          'qrContent': intent.qrContent,
          'checkoutUrl': intent.checkoutUrl,
          'expiredAt': intent.expiredAt?.toIso8601String(),
          'transactionDate': intent.transactionDate?.toIso8601String(),
        },
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingPaymentSession.fromJson(Map<String, dynamic> json) {
    final intentJson = json['intent'] as Map<String, dynamic>;
    return PendingPaymentSession(
      planId: json['planId'] as int,
      planName: json['planName'] as String,
      price: (json['price'] as num).toDouble(),
      autoRenew: json['autoRenew'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      intent: CustomerPaymentIntent(
        paymentId: intentJson['paymentId'] as String,
        paymentCode: intentJson['paymentCode'] as String,
        amount: (intentJson['amount'] as num).toDouble(),
        paymentMethod: intentJson['paymentMethod'] as String,
        paymentType: intentJson['paymentType'] as String,
        qrContent: intentJson['qrContent'] as String?,
        checkoutUrl: intentJson['checkoutUrl'] as String?,
        expiredAt: intentJson['expiredAt'] != null
            ? DateTime.parse(intentJson['expiredAt'] as String)
            : null,
        transactionDate: intentJson['transactionDate'] != null
            ? DateTime.parse(intentJson['transactionDate'] as String)
            : null,
      ),
    );
  }
}

