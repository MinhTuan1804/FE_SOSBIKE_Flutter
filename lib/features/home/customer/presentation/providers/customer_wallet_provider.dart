import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/repositories/customer_wallet_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';

class CustomerWalletProvider extends ChangeNotifier {
  CustomerWalletProvider(this._repository);

  final CustomerWalletRepository _repository;

  MechanicWalletData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  MechanicWalletData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MechanicWalletTransaction> get transactions => _data?.transactions ?? const [];

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _data != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.getWallet();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('CustomerWalletProvider.load: $e');
      }
      _data = const MechanicWalletData(balance: 0, transactions: []);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
