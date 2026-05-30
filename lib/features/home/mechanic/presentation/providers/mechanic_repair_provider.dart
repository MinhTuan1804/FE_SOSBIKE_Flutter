import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_session_spare_part.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_repair_repository.dart';

/// Dev fallback khi chưa có đơn active từ API.
const kDevActiveOrderId = 'd1111111-1111-1111-1111-111111111199';

class MechanicRepairProvider extends ChangeNotifier {
  MechanicRepairProvider(this._repository);

  final MechanicRepairRepository _repository;

  List<MechanicRepairLineItem> _services = MechanicRepairLineItem.sampleServices;
  List<MechanicSparePartDto> _catalogSpareParts = const [];
  String? _activeOrderId;
  bool _isLoadingServices = false;
  bool _isLoadingSpareParts = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<MechanicRepairLineItem> get services => _services;
  List<MechanicSparePartDto> get catalogSpareParts => _catalogSpareParts;
  String? get activeOrderId => _activeOrderId;
  bool get isLoadingServices => _isLoadingServices;
  bool get isLoadingSpareParts => _isLoadingSpareParts;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadServices({bool force = false}) async {
    if (_isLoadingServices) return;
    if (!force && _services.isNotEmpty && _services != MechanicRepairLineItem.sampleServices) return;

    _isLoadingServices = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dtos = await _repository.getServices();
      if (dtos.isNotEmpty) {
        _services = dtos
            .map(
              (d) => MechanicRepairLineItem(
                id: d.serviceId.toString(),
                serviceId: d.serviceId,
                label: d.name,
                laborFee: d.laborFee,
              ),
            )
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        _services = MechanicRepairLineItem.sampleServices;
      }
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  Future<void> loadSpareParts({bool force = false}) async {
    if (_isLoadingSpareParts) return;
    if (!force && _catalogSpareParts.isNotEmpty) return;

    _isLoadingSpareParts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _catalogSpareParts = await _repository.getSpareParts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingSpareParts = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveOrder() async {
    _errorMessage = null;
    try {
      final order = await _repository.getActiveOrder();
      _activeOrderId = order?.orderId;
      if (_activeOrderId == null && kDebugMode) {
        _activeOrderId = kDevActiveOrderId;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        _activeOrderId = kDevActiveOrderId;
      }
    }
    notifyListeners();
  }

  List<OrderQuoteLinePayload> _buildLines(
    List<MechanicRepairLineItem> selectedServices,
    List<MechanicSessionSparePart> spareParts,
  ) {
    return [
      ...selectedServices.map(
        (s) => OrderQuoteLinePayload(
          itemType: 'SERVICE',
          serviceId: s.serviceId ?? int.tryParse(s.id),
          itemName: s.label,
          unitPrice: s.laborFee,
        ),
      ),
      ...spareParts.map(
        (p) => OrderQuoteLinePayload(
          itemType: 'PART',
          partId: p.catalogPartId,
          itemName: p.name,
          unitPrice: p.price,
        ),
      ),
    ];
  }

  Future<bool> saveQuote({
    required List<MechanicRepairLineItem> selectedServices,
    List<MechanicSessionSparePart> spareParts = const [],
    String? mechanicNote,
  }) async {
    final orderId = _activeOrderId ?? (kDebugMode ? kDevActiveOrderId : null);
    if (orderId == null) {
      _errorMessage = 'Không có đơn đang xử lý.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveQuote(
        orderId,
        lines: _buildLines(selectedServices, spareParts),
        mechanicNote: mechanicNote,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> completeRepair({
    required List<MechanicRepairLineItem> selectedServices,
    required List<MechanicSessionSparePart> spareParts,
    String? mechanicNote,
  }) async {
    final orderId = _activeOrderId ?? (kDebugMode ? kDevActiveOrderId : null);
    if (orderId == null) {
      _errorMessage = 'Không có đơn đang xử lý.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.completeRepair(
        orderId,
        lines: _buildLines(selectedServices, spareParts),
        mechanicNote: mechanicNote,
      );
      _activeOrderId = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
