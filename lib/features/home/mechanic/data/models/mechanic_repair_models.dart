class RepairServiceDto {
  const RepairServiceDto({
    required this.serviceId,
    required this.name,
    required this.laborFee,
    this.description,
  });

  final int serviceId;
  final String name;
  final int laborFee;
  final String? description;

  factory RepairServiceDto.fromJson(Map<String, dynamic> json) {
    return RepairServiceDto(
      serviceId: (json['serviceId'] as num).toInt(),
      name: json['name'] as String? ?? '',
      laborFee: (json['laborFee'] as num).round(),
      description: json['description'] as String?,
    );
  }
}

class ActiveMechanicOrderDto {
  const ActiveMechanicOrderDto({
    required this.orderId,
    required this.status,
    required this.requestAddress,
    this.customerName,
  });

  final String orderId;
  final String status;
  final String requestAddress;
  final String? customerName;

  factory ActiveMechanicOrderDto.fromJson(Map<String, dynamic> json) {
    return ActiveMechanicOrderDto(
      orderId: json['orderId'] as String,
      status: json['status'] as String? ?? '',
      requestAddress: json['requestAddress'] as String? ?? '',
      customerName: json['customerName'] as String?,
    );
  }
}

class MechanicSparePartDto {
  const MechanicSparePartDto({
    required this.partId,
    required this.name,
    required this.price,
  });

  final String partId;
  final String name;
  final int price;

  factory MechanicSparePartDto.fromJson(Map<String, dynamic> json) {
    return MechanicSparePartDto(
      partId: json['partId'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num).round(),
    );
  }
}

class OrderQuoteLinePayload {
  const OrderQuoteLinePayload({
    required this.itemType,
    required this.itemName,
    required this.unitPrice,
    this.serviceId,
    this.partId,
    this.quantity = 1,
  });

  final String itemType;
  final int? serviceId;
  final String? partId;
  final String itemName;
  final int quantity;
  final int unitPrice;

  Map<String, dynamic> toJson() => {
        'itemType': itemType,
        if (serviceId != null) 'serviceId': serviceId,
        if (partId != null) 'partId': partId,
        'itemName': itemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}
