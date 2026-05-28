import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_customer_history_entry.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_history_repository.dart';

class MechanicHistoryProvider extends ChangeNotifier {
  MechanicHistoryProvider(this._repository);

  final MechanicHistoryRepository _repository;

  List<MechanicCustomerHistoryEntry> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalCount = 0;

  List<MechanicCustomerHistoryEntry> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _totalCount;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _items.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.getCustomerHistory();
      _items = page.items;
      _totalCount = page.totalCount;
      if (kDebugMode && _items.isEmpty) {
        _items = MechanicCustomerHistoryEntry.sampleEntries;
        _totalCount = _items.length;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode && _items.isEmpty) {
        _items = MechanicCustomerHistoryEntry.sampleEntries;
        _totalCount = _items.length;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
