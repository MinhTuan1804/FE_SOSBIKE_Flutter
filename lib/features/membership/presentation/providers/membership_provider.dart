import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';
import 'package:fe_moblie_flutter/features/membership/data/repositories/membership_repository.dart';

class MembershipProvider extends ChangeNotifier {
  MembershipProvider(this._repository);

  final MembershipRepository _repository;
  final _secureStorage = const FlutterSecureStorage();
  static const _sessionKey = 'pending_membership_payment_session';

  List<CustomerMembershipPlan> _plans = [];
  CustomerSubscription? _currentSubscription;
  PendingPaymentSession? _pendingSession;
  bool _isLoading = false;
  bool _isSubscribing = false;
  bool _isCancellingRenewal = false;
  String? _errorMessage;

  List<CustomerMembershipPlan> get plans => _plans;
  CustomerSubscription? get currentSubscription => _currentSubscription;
  PendingPaymentSession? get pendingSession => _pendingSession;
  bool get isLoading => _isLoading;
  bool get isSubscribing => _isSubscribing;
  bool get isCancellingRenewal => _isCancellingRenewal;
  String? get errorMessage => _errorMessage;

  Future<void> savePendingSession(PendingPaymentSession session) async {
    _pendingSession = session;
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
    notifyListeners();
  }

  Future<void> clearPendingSession() async {
    _pendingSession = null;
    await _secureStorage.delete(key: _sessionKey);
    notifyListeners();
  }


  bool canSubscribe(CustomerMembershipPlan plan) {
    if (plan.isCurrentPlan) return false;
    final current = _currentSubscription;
    if (current == null) return true;
    if (!current.endDate.isAfter(DateTime.now())) return true;
    final currentPlan = _findPlan(current.planId);
    if (currentPlan == null) return true;
    return plan.rank >= currentPlan.rank;
  }

  String? subscribeRestriction(CustomerMembershipPlan plan) {
    if (plan.isCurrentPlan) return 'Bạn đang sử dụng gói này.';
    final current = _currentSubscription;
    if (current == null || !current.endDate.isAfter(DateTime.now())) return null;
    final currentPlan = _findPlan(current.planId);
    if (currentPlan != null && plan.rank < currentPlan.rank) {
      return 'Không thể hạ cấp khi gói hiện tại còn hiệu lực.';
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plans = await _repository.getPlans();
      final currentSubscription = await _repository.getCurrentSubscription();
      _plans = _markCurrentPlan(plans, currentSubscription?.planId);
      _currentSubscription = currentSubscription;

      final sessionStr = await _secureStorage.read(key: _sessionKey);
      if (sessionStr != null) {
        try {
          final session = PendingPaymentSession.fromJson(
            jsonDecode(sessionStr) as Map<String, dynamic>,
          );
          final diff = DateTime.now().difference(session.createdAt);
          if (diff.inMinutes >= 15) {
            await clearPendingSession();
          } else {
            _pendingSession = session;
          }
        } catch (_) {
          await clearPendingSession();
        }
      } else {
        _pendingSession = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> subscribe(CustomerMembershipPlan plan, {required bool autoRenew}) async {
    final restriction = subscribeRestriction(plan);
    if (restriction != null) {
      _errorMessage = restriction;
      notifyListeners();
      return false;
    }

    _isSubscribing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSubscription = await _repository.subscribe(
        planId: plan.planId,
        autoRenew: autoRenew,
      );
      _plans = _plans
          .map((item) => CustomerMembershipPlan(
                planId: item.planId,
                name: item.name,
                targetAudience: item.targetAudience,
                price: item.price,
                durationDays: item.durationDays,
                billingCycle: item.billingCycle,
                description: item.description,
                isFree: item.isFree,
                isCurrentPlan: item.planId == plan.planId,
                benefits: item.benefits,
              ))
          .toList();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubscribing = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRenewal() async {
    final current = _currentSubscription;
    if (current == null) {
      _errorMessage = 'Bạn chưa có gói thành viên đang hoạt động.';
      notifyListeners();
      return false;
    }

    if (current.price <= 0) {
      _errorMessage = 'Gói miễn phí không cần hủy gia hạn.';
      notifyListeners();
      return false;
    }

    if (!current.autoRenew) {
      _errorMessage = 'Gói này đã tắt tự động gia hạn.';
      notifyListeners();
      return false;
    }

    _isCancellingRenewal = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSubscription = await _repository.cancelRenewal();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isCancellingRenewal = false;
      notifyListeners();
    }
  }

  Future<CustomerPaymentIntent?> createPaymentIntent(
    CustomerMembershipPlan plan, {
    required String paymentMethod,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository.createPaymentIntent(
        planId: plan.planId,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> confirmPayment({
    required String paymentId,
    required bool autoRenew,
  }) async {
    _isSubscribing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSubscription = await _repository.confirmPayment(
        paymentId: paymentId,
        autoRenew: autoRenew,
      );
      await clearPendingSession();
      await load();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubscribing = false;
      notifyListeners();
    }
  }

  List<CustomerMembershipPlan> _markCurrentPlan(
    List<CustomerMembershipPlan> plans,
    int? currentPlanId,
  ) {
    return plans
        .map(
          (item) => CustomerMembershipPlan(
            planId: item.planId,
            name: item.name,
            targetAudience: item.targetAudience,
            price: item.price,
            durationDays: item.durationDays,
            billingCycle: item.billingCycle,
            description: item.description,
            isFree: item.isFree,
            isCurrentPlan: currentPlanId != null && item.planId == currentPlanId,
            benefits: item.benefits,
          ),
        )
        .toList();
  }

  Future<bool> resetSubscriptionForDebug() async {
    try {
      await _repository.resetTestSubscription();
      await load();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createPaymentAndSubscribe(
    CustomerMembershipPlan plan, {
    required bool autoRenew,
    required String paymentMethod,
  }) async {
    final intent = await createPaymentIntent(plan, paymentMethod: paymentMethod);
    if (intent == null || intent.paymentId.isEmpty) return false;
    return confirmPayment(paymentId: intent.paymentId, autoRenew: autoRenew);
  }

  CustomerMembershipPlan? _findPlan(int planId) {
    for (final plan in _plans) {
      if (plan.planId == planId) return plan;
    }
    return null;
  }
}
