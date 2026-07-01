import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import '../models/vehicle_model.dart';
import 'dart:io';

class VehicleRepository {
  final DioClient _dioClient;

  VehicleRepository(this._dioClient);

  Future<List<VehicleModel>> getMyVehicles() async {
    try {
      final response = await _dioClient.dio.get('/vehicles/mine');
      final List<dynamic> data = response.data;
      return data.map((json) => VehicleModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VehicleModel> addMyVehicle({
    required String brand,
    required String model,
    required String licenseplate,
    required String vehicleType,
    int? yearOfManufacture,
    String? color,
    int? currentMileage,
    File? photoFile,
  }) async {
    try {
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _uploadVehicleImage(photoFile);
      }

      final response = await _dioClient.dio.post('/vehicles/mine', data: {
        'brand': brand,
        'model': model,
        'licenseplate': licenseplate,
        'vehicleType': vehicleType,
        'yearOfManufacture': yearOfManufacture,
        'color': color,
        'currentMileage': currentMileage,
        'photoUrl': photoUrl,
      });

      return VehicleModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> _uploadVehicleImage(File file) async {
    final fileName = file.path.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _dioClient.dio.post('/vehicles/mine/photo', data: formData);
    final data = response.data;
    if (data is Map && data['photoUrl'] != null) {
      return data['photoUrl'] as String;
    }
    throw StateError('Upload ảnh xe thất bại.');
  }
}
