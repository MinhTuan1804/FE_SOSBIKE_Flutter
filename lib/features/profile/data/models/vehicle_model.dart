import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model.g.dart';

@JsonSerializable()
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

  factory VehicleModel.fromJson(Map<String, dynamic> json) => _$VehicleModelFromJson(json);
  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);
}
