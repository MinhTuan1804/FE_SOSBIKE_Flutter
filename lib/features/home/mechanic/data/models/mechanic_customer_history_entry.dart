class MechanicCustomerHistoryEntry {
  const MechanicCustomerHistoryEntry({
    required this.id,
    required this.customerName,
    required this.completedAt,
    required this.rating,
    required this.vehicleLabel,
    required this.address,
    required this.totalAmount,
    required this.paymentMethod,
    required this.hasReview,
    this.reviewComment,
    this.avatarUrl,
  });

  final String id;
  final String customerName;
  final DateTime completedAt;
  final int? rating;
  final String vehicleLabel;
  final String address;
  final int totalAmount;
  final String paymentMethod;
  final bool hasReview;
  final String? reviewComment;
  final String? avatarUrl;

  factory MechanicCustomerHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MechanicCustomerHistoryEntry(
      id: json['orderId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Khách hàng',
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
      rating: _toNullableInt(json['rating']),
      vehicleLabel: json['vehicleLabel']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      totalAmount: _toInt(json['totalAmount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Tiền mặt',
      hasReview: _toBool(json['hasReview']) || json['reviewId'] != null,
      reviewComment: json['reviewComment']?.toString(),
      avatarUrl: json['customerAvatarUrl']?.toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static bool _toBool(Object? value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  String get totalAmountLabel {
    final formatted = totalAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }
}
