class CustomerOrderHistoryEntry {
  const CustomerOrderHistoryEntry({
    required this.id,
    required this.mechanicName,
    required this.completedAt,
    required this.rating,
    required this.vehicleLabel,
    required this.address,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.avatarUrl,
  });

  final String id;
  final String mechanicName;
  final DateTime completedAt;
  final int rating;
  final String vehicleLabel;
  final String address;
  final int totalAmount;
  final String paymentMethod;
  final String status;
  final String? avatarUrl;

  factory CustomerOrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CustomerOrderHistoryEntry(
      id: json['orderId']?.toString() ?? '',
      mechanicName: json['mechanicName']?.toString() ?? 'Thợ SOSbike',
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
      rating: _toInt(json['rating']),
      vehicleLabel: json['vehicleLabel']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      totalAmount: _toInt(json['totalAmount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Tiền mặt',
      status: json['status']?.toString() ?? 'COMPLETED',
      avatarUrl: json['mechanicAvatarUrl']?.toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get totalAmountLabel {
    final formatted = totalAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  bool get isActive =>
      status != 'COMPLETED' &&
      status != 'CANCELLED' &&
      status != 'CANCELLED_AFTER_ARRIVED';

  String get statusLabel {
    return switch (status.toUpperCase()) {
      'PENDING' => 'Đang tìm thợ',
      'ACCEPTED' => 'Đang di chuyển',
      'ARRIVED' => 'Đã đến nơi',
      'QUOTING' => 'Đang báo giá',
      'REPAIRING' => 'Đang sửa chữa',
      'COMPLETED' => 'Đã hoàn tất',
      'CANCELLED' => 'Đã hủy',
      'CANCELLED_AFTER_ARRIVED' => 'Hủy sau khi đến',
      _ => 'Đang xử lý',
    };
  }
}
