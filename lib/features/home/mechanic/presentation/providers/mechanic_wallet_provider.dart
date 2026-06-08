import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_wallet_repository.dart';
import 'package:flutter/foundation.dart';

class MechanicWalletProvider extends ChangeNotifier {
  MechanicWalletProvider(this._repository);

  final MechanicWalletRepository _repository;

  MechanicWalletData? _data;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasWallet = true;
  bool? _hasPin;
  bool _isPinUnlocked = false;

  DateTime? _startDate;
  DateTime? _endDate;

  MechanicWalletData? get data => _data;
  bool get hasWallet => _hasWallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MechanicWalletTransaction> get transactions => _data?.transactions ?? const [];
  List<MechanicWithdrawRequest> get withdrawRequests => _data?.withdrawRequests ?? const [];
  bool? get hasPin => _hasPin;
  bool get isPinUnlocked => _isPinUnlocked;

  /// Tạo ví → PIN → liên kết ngân hàng: ẩn header/nav shell.
  bool isInWalletSetupFlow({required bool hasBankLinked}) {
    if (_hasPin == false) return true;
    if (_hasPin == true && !_isPinUnlocked) return true;
    if (_isPinUnlocked && !hasBankLinked) return true;
    return false;
  }

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    // Set end date to end of day to include all transactions on that day
    if (end != null) {
      _endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    } else {
      _endDate = null;
    }
    notifyListeners();
    load(force: true);
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
    load(force: true);
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _data != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.getWallet(
        startDate: _startDate,
        endDate: _endDate,
      );
      _hasWallet = true;
      try {
        final pinStatus = await _repository.checkPinStatus();
        _hasPin = pinStatus.hasPin;
      } catch (e) {
        debugPrint('checkPinStatus failed: $e');
        _hasPin = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);

  Future<void> checkWalletPinStatus() async {
    try {
      final pinStatus = await _repository.checkPinStatus();
      _hasWallet = true;
      _hasPin = pinStatus.hasPin;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> createWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _data = await _repository.createWallet();
      _hasWallet = _data?.hasWallet ?? true;
      _hasPin = false;
      _isPinUnlocked = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> setupWalletPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.setupPin(pin);
      _hasPin = true;
      _isPinUnlocked = true; // Auto unlock after setup
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyWalletPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final ok = await _repository.verifyPin(pin);
      if (ok) {
        _isPinUnlocked = true;
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void lockWallet() {
    _isPinUnlocked = false;
    notifyListeners();
  }

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
  Future<bool> withdraw(int amount, {String? description, String? otpToken}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.withdraw(amount, description: description, otpToken: otpToken);
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
