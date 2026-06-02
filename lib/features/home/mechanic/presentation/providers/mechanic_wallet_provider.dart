import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_wallet_repository.dart';

class MechanicWalletProvider extends ChangeNotifier {
  MechanicWalletProvider(this._repository);

  final MechanicWalletRepository _repository;

  MechanicWalletData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  MechanicWalletData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MechanicWalletTransaction> get transactions => _data?.transactions ?? const [];
  List<MechanicWithdrawRequest> get withdrawRequests => _data?.withdrawRequests ?? const [];

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _data != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.getWallet();
      if (kDebugMode && (_data?.transactions.isEmpty ?? true) && (_data?.balance ?? 0) == 0) {
        _data = MechanicWalletData.sample;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        _data = MechanicWalletData.sample;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);

  Future<Map<String, dynamic>?> createPaymentIntent(int amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.createPaymentIntent(amount);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> checkPaymentStatus(String paymentId) async {
    try {
      final result = await _repository.getPaymentStatus(paymentId);
      final status = result['status'] as String?;
      if (status?.toUpperCase() == 'PAID' || status?.toUpperCase() == 'SUCCESS') {
        await load(force: true);
      }
      return status;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Nạp tiền (trả về true nếu thành công)
  Future<bool> deposit(int amount, {String? description}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deposit(amount, description: description);
      await load(force: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rút tiền (trả về true nếu tạo request thành công)
  Future<bool> withdraw(int amount, {String? description}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.withdraw(amount, description: description);
      await load(force: true);
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
