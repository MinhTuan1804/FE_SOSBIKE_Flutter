import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/models/customer_order_history_entry.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/repositories/customer_history_repository.dart';

class CustomerHistoryProvider extends ChangeNotifier {
  CustomerHistoryProvider(this._repository);

  final CustomerHistoryRepository _repository;

  List<CustomerOrderHistoryEntry> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerOrderHistoryEntry> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _items.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.getOrderHistory();
      _items = page.items;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('CustomerHistoryProvider.load: $e');
      }
      _items = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
