import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/profile/data/models/vehicle_model.dart';
import 'package:fe_moblie_flutter/features/profile/data/repositories/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleRepository _repository;

  VehicleProvider(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  List<VehicleModel> _vehicles = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VehicleModel> get vehicles => _vehicles;

  Future<void> fetchMyVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await _repository.getMyVehicles();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVehicle({
    required String brand,
    required String model,
    required String licenseplate,
    required String vehicleType,
    int? yearOfManufacture,
    String? color,
    int? currentMileage,
    File? photoFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newVehicle = await _repository.addMyVehicle(
        brand: brand,
        model: model,
        licenseplate: licenseplate,
        vehicleType: vehicleType,
        yearOfManufacture: yearOfManufacture,
        color: color,
        currentMileage: currentMileage,
        photoFile: photoFile,
      );
      _vehicles.add(newVehicle);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
