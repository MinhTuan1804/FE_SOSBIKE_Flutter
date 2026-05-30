import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_priority_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_subscription_repository.dart';

class MechanicSubscriptionProvider extends ChangeNotifier {
  MechanicSubscriptionProvider(this._repository);

  final MechanicSubscriptionRepository _repository;

  MechanicCurrentSubscription _subscription = MechanicCurrentSubscription.empty;
  bool _isLoading = false;
  String? _error;

  MechanicCurrentSubscription get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _subscription.hasActivePlan) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = await _repository.getSubscription();
    } catch (e) {
      _error = e.toString();
      debugPrint('MechanicSubscriptionProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
