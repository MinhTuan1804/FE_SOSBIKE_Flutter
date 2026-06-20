import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_service_offering_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_service_offering_repository.dart';

class MechanicServiceOfferingProvider extends ChangeNotifier {
  MechanicServiceOfferingProvider(this._repository);

  final MechanicServiceOfferingRepository _repository;

  List<MechanicServiceOfferingDto> _items = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<MechanicServiceOfferingDto> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _items.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.listMine();
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String serviceName,
    required int laborFee,
    String? description,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.create(
        CreateMechanicServicePayload(
          serviceName: serviceName,
          laborFee: laborFee,
          description: description,
        ),
      );
      _items = [created, ..._items];
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> delete(int mechanicServiceId) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.delete(mechanicServiceId);
      _items = _items.where((e) => e.mechanicServiceId != mechanicServiceId).toList();
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
