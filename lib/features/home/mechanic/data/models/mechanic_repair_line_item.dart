class MechanicRepairLineItem {
  const MechanicRepairLineItem({
    required this.id,
    required this.label,
    required this.price,
    this.selected = false,
  });

  final String id;
  final String label;
  final int price;
  final bool selected;

  String get priceLabel {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formatted VND';
  }

  MechanicRepairLineItem copyWith({bool? selected}) {
    return MechanicRepairLineItem(
      id: id,
      label: label,
      price: price,
      selected: selected ?? this.selected,
    );
  }

  static const sampleItems = [
    MechanicRepairLineItem(id: '1', label: 'Vá săm (có ruột)', price: 90000),
    MechanicRepairLineItem(id: '2', label: 'Thay lốp xe', price: 250000),
    MechanicRepairLineItem(id: '3', label: 'Bơm hơi lốp xe', price: 20000),
    MechanicRepairLineItem(id: '4', label: 'Kiểm tra phanh', price: 50000),
  ];
}
