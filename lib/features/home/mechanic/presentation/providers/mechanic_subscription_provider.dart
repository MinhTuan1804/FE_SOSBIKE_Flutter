import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_priority_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_subscription_repository.dart';

class MechanicSubscriptionProvider extends ChangeNotifier {
  MechanicSubscriptionProvider(this._repository);

  final MechanicSubscriptionRepository _repository;

  MechanicCurrentSubscription _subscription = MechanicCurrentSubscription.empty;
  List<MechanicPriorityPlan> _plans = const [];
  bool _isLoading = false;
  bool _isLoadingPlans = false;
  bool _isSubscribing = false;
  String? _error;

  MechanicCurrentSubscription get subscription => _subscription;
  List<MechanicPriorityPlan> get plans =>
      _plans.isNotEmpty ? _plans : MechanicPriorityPlan.plans;
  bool get isLoading => _isLoading;
  bool get isLoadingPlans => _isLoadingPlans;
  bool get isSubscribing => _isSubscribing;
  String? get error => _error;
  bool get plansFromApi => _plans.isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _subscription.hasActivePlan && _subscription.planId != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = await _repository.getSubscription();
    } catch (e) {
      _error = errorMessageFrom(e);
      debugPrint('MechanicSubscriptionProvider.load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlans({bool force = false}) async {
    if (_isLoadingPlans) return;
    if (!force && _plans.isNotEmpty) return;

    _isLoadingPlans = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _repository.getPlans();
    } catch (e) {
      _error = errorMessageFrom(e);
      debugPrint('MechanicSubscriptionProvider.loadPlans error: $e');
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> loadAll({bool force = false}) async {
    await Future.wait([
      load(force: force),
      loadPlans(force: force),
    ]);
  }

  Future<bool> subscribe({
    required int planId,
    bool autoRenew = false,
    String paymentMethod = 'WALLET',
  }) async {
    _isSubscribing = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = await _repository.subscribe(
        planId: planId,
        autoRenew: autoRenew,
        paymentMethod: paymentMethod,
      );
      return true;
    } catch (e) {
      _error = errorMessageFrom(e);
      return false;
    } finally {
      _isSubscribing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadAll(force: true);
}
