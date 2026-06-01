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
    this.avatarUrl,
  });

  final String id;
  final String customerName;
  final DateTime completedAt;
  final int rating;
  final String vehicleLabel;
  final String address;
  final int totalAmount;
  final String paymentMethod;
  final String? avatarUrl;

  factory MechanicCustomerHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MechanicCustomerHistoryEntry(
      id: json['orderId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Khách hàng',
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
      rating: _toInt(json['rating']),
      vehicleLabel: json['vehicleLabel']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      totalAmount: _toInt(json['totalAmount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Tiền mặt',
      avatarUrl: json['customerAvatarUrl']?.toString(),
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

  static final sampleEntries = [
    MechanicCustomerHistoryEntry(
      id: '1',
      customerName: 'Khánh Linh',
      completedAt: DateTime(2026, 3, 15, 14, 30),
      rating: 5,
      vehicleLabel: 'Honda SH 150i - 59-P1 123.45',
      address: 'Chung cư petroland, đường 62, phường Bình Trưng, Thành phố Thủ Đức.',
      totalAmount: 250000,
      paymentMethod: 'Tiền mặt',
    ),
    MechanicCustomerHistoryEntry(
      id: '2',
      customerName: 'Khánh Linh',
      completedAt: DateTime(2026, 3, 15, 14, 30),
      rating: 5,
      vehicleLabel: 'Honda SH 150i - 59-P1 123.45',
      address: 'Chung cư petroland, đường 62, phường Bình Trưng, Thành phố Thủ Đức.',
      totalAmount: 250000,
      paymentMethod: 'Tiền mặt',
    ),
    MechanicCustomerHistoryEntry(
      id: '3',
      customerName: 'Khánh Linh',
      completedAt: DateTime(2026, 3, 15, 14, 30),
      rating: 5,
      vehicleLabel: 'Honda SH 150i - 59-P1 123.45',
      address: 'Chung cư petroland, đường 62, phường Bình Trưng, Thành phố Thủ Đức.',
      totalAmount: 250000,
      paymentMethod: 'Tiền mặt',
    ),
  ];
}
