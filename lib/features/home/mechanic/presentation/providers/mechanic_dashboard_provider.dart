import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_dashboard_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_dashboard_repository.dart';

class MechanicDashboardProvider extends ChangeNotifier {
  MechanicDashboardProvider(this._repository);

  final MechanicDashboardRepository _repository;

  MechanicDashboardData? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  MechanicDashboardData? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _dashboard != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getDashboard();
      _dashboard = data;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
