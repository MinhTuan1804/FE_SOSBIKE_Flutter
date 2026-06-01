import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/local/mechanic_order_flow_store.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_line_item.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_session_spare_part.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_repair_repository.dart';

class MechanicRepairProvider extends ChangeNotifier {
  MechanicRepairProvider(this._repository);

  final MechanicRepairRepository _repository;

  List<MechanicRepairLineItem> _services = MechanicRepairLineItem.sampleServices;
  List<MechanicSparePartDto> _catalogSpareParts = const [];
  String? _activeOrderId;
  ActiveMechanicOrderDto? _activeOrder;
  bool _isLoadingServices = false;
  bool _isLoadingSpareParts = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<MechanicRepairLineItem> get services => _services;
  List<MechanicSparePartDto> get catalogSpareParts => _catalogSpareParts;
  String? get activeOrderId => _activeOrderId;
  ActiveMechanicOrderDto? get activeOrder => _activeOrder;
  bool get hasActiveOrder => _activeOrderId != null;
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
      _errorMessage = errorMessageFrom(e);
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
      _errorMessage = errorMessageFrom(e);
    } finally {
      _isLoadingSpareParts = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveOrder() async {
    _errorMessage = null;
    try {
      final order = await _repository.getActiveOrder();
      _activeOrder = order;
      _activeOrderId = order?.orderId;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
    }
    notifyListeners();
  }

  /// Dev: nhận đơn popup → gán đơn test trên BE cho đúng thợ đang đăng nhập.
  Future<bool> acceptDevIncomingOrder() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _repository.simulateDevAcceptOrder();
      _activeOrderId = order.orderId;
      _activeOrder = order;
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Khôi phục dịch vụ + phụ tùng đã lưu trên đơn.
  Future<({List<MechanicRepairLineItem> services, List<MechanicSessionSparePart> parts})> restoreQuoteState() async {
    final orderId = _activeOrderId;
    if (orderId == null) {
      return (services: const <MechanicRepairLineItem>[], parts: const <MechanicSessionSparePart>[]);
    }

    try {
      final quote = await _repository.getQuote(orderId);
      _activeOrder = ActiveMechanicOrderDto(
        orderId: orderId,
        status: quote.status,
        requestAddress: _activeOrder?.requestAddress ?? '',
        customerName: _activeOrder?.customerName,
      );

      final serviceLines = quote.lines.where((l) => l.itemType.toUpperCase() == 'SERVICE').toList();
      final partLines = quote.lines.where((l) => l.itemType.toUpperCase() == 'PART').toList();

      final selectedServices = serviceLines
          .map(
            (l) => MechanicRepairLineItem(
              id: (l.serviceId ?? l.itemName.hashCode).toString(),
              serviceId: l.serviceId,
              label: l.itemName,
              laborFee: l.unitPrice,
              selected: true,
            ),
          )
          .toList();

      final spareParts = partLines
          .map(
            (l) => l.partId != null
                ? MechanicSessionSparePart.fromCatalog(
                    partId: l.partId!,
                    name: l.itemName,
                    price: l.unitPrice,
                  )
                : MechanicSessionSparePart(
                    id: l.itemName.hashCode.toString(),
                    name: l.itemName,
                    price: l.unitPrice,
                  ),
          )
          .toList();

      return (services: selectedServices, parts: spareParts);
    } catch (_) {
      return (services: const <MechanicRepairLineItem>[], parts: const <MechanicSessionSparePart>[]);
    }
  }

  Future<void> clearActiveOrderState() async {
    _activeOrderId = null;
    _activeOrder = null;
    await MechanicOrderFlowStore.clear();
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

  String? get _orderIdOrError {
    final orderId = _activeOrderId;
    if (orderId == null) {
      _errorMessage = 'Chưa có đơn active. Hãy nhận đơn từ popup hoặc Lịch sử → Tiếp tục đơn.';
      notifyListeners();
    }
    return orderId;
  }

  Future<bool> confirmArrival() async {
    await loadActiveOrder();
    final orderId = _orderIdOrError;
    if (orderId == null) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _repository.confirmArrival(orderId);
      _activeOrderId = order.orderId;
      _activeOrder = order;
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> startRepair() async {
    await loadActiveOrder();
    final orderId = _orderIdOrError;
    if (orderId == null) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _repository.startRepair(orderId);
      _activeOrderId = order.orderId;
      _activeOrder = order;
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> saveQuote({
    required List<MechanicRepairLineItem> selectedServices,
    List<MechanicSessionSparePart> spareParts = const [],
    String? mechanicNote,
  }) async {
    await loadActiveOrder();
    final orderId = _orderIdOrError;
    if (orderId == null) return false;

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
      _errorMessage = errorMessageFrom(e);
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
    await loadActiveOrder();
    final orderId = _orderIdOrError;
    if (orderId == null) return false;

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
      _activeOrder = null;
      await MechanicOrderFlowStore.clear();
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
