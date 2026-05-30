class VehicleModel {
  final String vehicleid;
  final String brand;
  final String model;
  final String licenseplate;
  final String vehicletype;
  final int? yearofmanufacture;
  final String? color;
  final int? currentmileage;
  final String? photourl;

  VehicleModel({
    required this.vehicleid,
    required this.brand,
    required this.model,
    required this.licenseplate,
    required this.vehicletype,
    this.yearofmanufacture,
    this.color,
    this.currentmileage,
    this.photourl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleid: '${json['vehicleId'] ?? json['vehicleid'] ?? ''}',
      brand: '${json['brand'] ?? ''}',
      model: '${json['model'] ?? ''}',
      licenseplate: '${json['licensePlate'] ?? json['licenseplate'] ?? ''}',
      vehicletype: '${json['vehicleType'] ?? json['vehicletype'] ?? ''}',
      yearofmanufacture: (json['yearOfManufacture'] ?? json['yearofmanufacture']) as int?,
      color: json['color'] as String?,
      currentmileage: (json['currentMileage'] ?? json['currentmileage']) as int?,
      photourl: json['photoUrl'] as String? ?? json['photourl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleid,
      'brand': brand,
      'model': model,
      'licensePlate': licenseplate,
      'vehicleType': vehicletype,
      if (yearofmanufacture != null) 'yearOfManufacture': yearofmanufacture,
      if (color != null) 'color': color,
      if (currentmileage != null) 'currentMileage': currentmileage,
      if (photourl != null) 'photoUrl': photourl,
    };
  }
}
