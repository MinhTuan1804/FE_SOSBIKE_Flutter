import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_customer_history_entry.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_income_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_history_repository.dart';

class MechanicIncomeProvider extends ChangeNotifier {
  MechanicIncomeProvider(this._repository);

  final MechanicHistoryRepository _repository;

  IncomePeriod _period = IncomePeriod.week;
  MechanicIncomeData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  IncomePeriod get period => _period;
  MechanicIncomeData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MechanicIncomeData get incomeData =>
      _data ?? MechanicIncomeData.empty(_period);

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _data != null && _data!.period == _period) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final range = _period.range;
      // Lấy tất cả đơn trong kỳ (pageSize 200 để bao hết)
      final page = await _repository.getCustomerHistory(
        page: 1,
        pageSize: 200,
        startDate: range.start,
        endDate: range.end,
      );
      _data = MechanicIncomeData.fromOrders(page.items, _period);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        // Dev fallback: tạo sample data
        _data = MechanicIncomeData.fromOrders(
          _buildSampleOrders(),
          _period,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(IncomePeriod period) async {
    if (_period == period) return;
    _period = period;
    _data = null;
    notifyListeners();
    await load();
  }

  Future<void> refresh() async {
    _data = null;
    await load();
  }

  /// Dev sample data
  List<MechanicCustomerHistoryEntry> _buildSampleOrders() {
    final now = DateTime.now();
    return [
      MechanicCustomerHistoryEntry(
        id: 's1',
        customerName: 'Khánh Linh',
        completedAt: now.subtract(const Duration(hours: 2)),
        rating: 5,
        vehicleLabel: 'Honda Wave',
        address: 'Q.7, HCM',
        totalAmount: 250000,
        paymentMethod: 'Tiền mặt',
      ),
      MechanicCustomerHistoryEntry(
        id: 's2',
        customerName: 'Minh Tuấn',
        completedAt: now.subtract(const Duration(days: 1, hours: 3)),
        rating: 4,
        vehicleLabel: 'Yamaha Exciter',
        address: 'Q.Bình Thạnh',
        totalAmount: 320000,
        paymentMethod: 'Tiền mặt',
      ),
      MechanicCustomerHistoryEntry(
        id: 's3',
        customerName: 'Phương Thảo',
        completedAt: now.subtract(const Duration(days: 2)),
        rating: 5,
        vehicleLabel: 'Honda SH',
        address: 'TP.Thủ Đức',
        totalAmount: 450000,
        paymentMethod: 'Chuyển khoản',
      ),
      MechanicCustomerHistoryEntry(
        id: 's4',
        customerName: 'Lê Thọ',
        completedAt: now.subtract(const Duration(days: 3)),
        rating: 4,
        vehicleLabel: 'Suzuki',
        address: 'Q.1',
        totalAmount: 180000,
        paymentMethod: 'Tiền mặt',
      ),
      MechanicCustomerHistoryEntry(
        id: 's5',
        customerName: 'Trần Duy',
        completedAt: now.subtract(const Duration(days: 5)),
        rating: 5,
        vehicleLabel: 'Honda Future',
        address: 'Q.12',
        totalAmount: 380000,
        paymentMethod: 'Tiền mặt',
      ),
    ];
  }
}
