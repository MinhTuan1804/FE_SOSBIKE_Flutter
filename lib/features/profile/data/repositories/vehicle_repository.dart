import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import '../models/vehicle_model.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        photoUrl = await _uploadVehicleImageToFirebase(photoFile);
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

  Future<String> _uploadVehicleImageToFirebase(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Người dùng chưa đăng nhập Firebase.');
    }

    final rawExt = file.path.contains('.') ? file.path.split('.').last : 'jpg';
    final ext = rawExt.toLowerCase() == 'jpg' ? 'jpeg' : rawExt.toLowerCase();
    final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('vehicles/${user.uid}/$fileName');

    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return await ref.getDownloadURL();
  }
}
