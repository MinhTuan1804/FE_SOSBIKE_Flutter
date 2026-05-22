// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) => VehicleModel(
  vehicleid: json['vehicleid'] as String,
  brand: json['brand'] as String,
  model: json['model'] as String,
  licenseplate: json['licenseplate'] as String,
  vehicletype: json['vehicletype'] as String,
  yearofmanufacture: (json['yearofmanufacture'] as num?)?.toInt(),
  color: json['color'] as String?,
  currentmileage: (json['currentmileage'] as num?)?.toInt(),
  photourl: json['photourl'] as String?,
);

Map<String, dynamic> _$VehicleModelToJson(VehicleModel instance) =>
    <String, dynamic>{
      'vehicleid': instance.vehicleid,
      'brand': instance.brand,
      'model': instance.model,
      'licenseplate': instance.licenseplate,
      'vehicletype': instance.vehicletype,
      'yearofmanufacture': instance.yearofmanufacture,
      'color': instance.color,
      'currentmileage': instance.currentmileage,
      'photourl': instance.photourl,
    };
