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
    this.customerLatitude,
    this.customerLongitude,
  });

  final String orderId;
  final String status;
  final String requestAddress;
  final String? customerName;
  final double? customerLatitude;
  final double? customerLongitude;

  factory ActiveMechanicOrderDto.fromJson(Map<String, dynamic> json) {
    return ActiveMechanicOrderDto(
      orderId: json['orderId'] as String,
      status: json['status'] as String? ?? '',
      requestAddress: json['requestAddress'] as String? ?? '',
      customerName: json['customerName'] as String?,
      customerLatitude: json['customerLatitude'] != null ? (json['customerLatitude'] as num).toDouble() : null,
      customerLongitude: json['customerLongitude'] != null ? (json['customerLongitude'] as num).toDouble() : null,
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

class OrderQuoteDto {
  const OrderQuoteDto({
    required this.orderId,
    required this.status,
    required this.lines,
    this.totalAmount = 0.0,
    this.travelFee = 0.0,
    this.nightSurcharge = 0.0,
    this.serviceTotal = 0.0,
    this.partsTotal = 0.0,
    this.repairFee = 0.0,
  });

  final String orderId;
  final String status;
  final List<OrderQuoteLineDto> lines;
  final double totalAmount;
  final double travelFee;
  final double nightSurcharge;
  final double serviceTotal;
  final double partsTotal;
  final double repairFee;

  factory OrderQuoteDto.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return OrderQuoteDto(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lines: rawLines is List
          ? rawLines
              .map((e) => OrderQuoteLineDto.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      travelFee: (json['travelFee'] as num?)?.toDouble() ?? 0.0,
      nightSurcharge: (json['nightSurcharge'] as num?)?.toDouble() ?? 0.0,
      serviceTotal: (json['serviceTotal'] as num?)?.toDouble() ?? 0.0,
      partsTotal: (json['partsTotal'] as num?)?.toDouble() ?? 0.0,
      repairFee: (json['repairFee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderQuoteLineDto {
  const OrderQuoteLineDto({
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

  factory OrderQuoteLineDto.fromJson(Map<String, dynamic> json) {
    return OrderQuoteLineDto(
      itemType: json['itemType']?.toString() ?? '',
      serviceId: json['serviceId'] is num ? (json['serviceId'] as num).toInt() : null,
      partId: json['partId']?.toString(),
      itemName: json['itemName']?.toString() ?? '',
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 1,
      unitPrice: json['unitPrice'] is num ? (json['unitPrice'] as num).round() : 0,
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
