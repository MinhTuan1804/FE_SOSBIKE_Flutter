/// Phụ tùng trên đơn sửa chữa.
/// - [catalogPartId] != null → lấy từ `mechanicspareparts`
/// - [catalogPartId] == null → dòng PART cộng thêm (nhập tay, chỉ đơn này)
class MechanicSessionSparePart {
  const MechanicSessionSparePart({
    required this.id,
    required this.name,
    required this.price,
    this.catalogPartId,
  });

  final String id;
  final String name;
  final int price;
  final String? catalogPartId;

  bool get isFromCatalog => catalogPartId != null;
  bool get isExtra => catalogPartId == null;

  String get priceLabel {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  MechanicSessionSparePart copyWith({String? name, int? price}) {
    return MechanicSessionSparePart(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      catalogPartId: catalogPartId,
    );
  }

  factory MechanicSessionSparePart.fromCatalog({
    required String partId,
    required String name,
    required int price,
  }) {
    return MechanicSessionSparePart(
      id: 'cat-$partId',
      catalogPartId: partId,
      name: name,
      price: price,
    );
  }
}
