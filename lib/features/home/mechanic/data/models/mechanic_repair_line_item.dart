/// Hạng mục **dịch vụ sửa chữa** (phí công) — do app quy định, không gồm phụ tùng.
class MechanicRepairLineItem {
  const MechanicRepairLineItem({
    required this.id,
    required this.label,
    required this.laborFee,
    this.serviceId,
    this.selected = false,
  });

  final String id;
  final String label;
  /// Phí dịch vụ / công sửa chữa (VND).
  final int laborFee;
  final int? serviceId;
  final bool selected;

  String get priceLabel {
    final formatted = laborFee.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  MechanicRepairLineItem copyWith({bool? selected}) {
    return MechanicRepairLineItem(
      id: id,
      label: label,
      laborFee: laborFee,
      serviceId: serviceId,
      selected: selected ?? this.selected,
    );
  }

  factory MechanicRepairLineItem.fromApi(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final serviceId = (map['serviceId'] as num).toInt();
    return MechanicRepairLineItem(
      id: serviceId.toString(),
      serviceId: serviceId,
      label: map['name'] as String? ?? '',
      laborFee: (map['laborFee'] as num).round(),
    );
  }

  /// Dịch vụ mẫu — fallback khi API chưa sẵn sàng.
  static const sampleServices = [
    MechanicRepairLineItem(id: '1', serviceId: 1, label: 'Vá săm (công)', laborFee: 30000),
    MechanicRepairLineItem(id: '2', serviceId: 2, label: 'Thay lốp (công)', laborFee: 50000),
    MechanicRepairLineItem(id: '3', serviceId: 3, label: 'Bơm hơi lốp', laborFee: 15000),
    MechanicRepairLineItem(id: '4', serviceId: 4, label: 'Kiểm tra phanh', laborFee: 40000),
  ];
}
