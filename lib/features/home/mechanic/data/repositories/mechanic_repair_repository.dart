import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_models.dart';

class MechanicRepairRepository {
  const MechanicRepairRepository(this._dioClient);

  final DioClient _dioClient;

  Future<List<RepairServiceDto>> getServices() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.mechanicRepairServices);
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Phản hồi danh sách dịch vụ sửa chữa không hợp lệ.');
      }
      return data
          .map((e) => RepairServiceDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<MechanicSparePartDto>> getSpareParts() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.mechanicSpareParts);
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Phản hồi danh sách phụ tùng thay thế không hợp lệ.');
      }
      return data
          .map((e) => MechanicSparePartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ActiveMechanicOrderDto?> getActiveOrder() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.mechanicActiveOrder);
      if (response.statusCode == 204 || response.data == null || response.data == '') {
        return null;
      }
      if (response.data is! Map) {
        throw const FormatException('Phản hồi đơn hàng đang hoạt động không hợp lệ.');
      }
      return ActiveMechanicOrderDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<OrderQuoteDto> getQuote(String orderId) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.mechanicOrderQuote(orderId));
      if (response.data is! Map) {
        throw const FormatException('Phản hồi báo giá không hợp lệ.');
      }
      return OrderQuoteDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ActiveMechanicOrderDto> simulateDevAcceptOrder() async {
    try {
      final response = await _dioClient.dio.post(ApiEndpoints.mechanicDevSimulateAccept);
      if (response.data is! Map) {
        throw const FormatException('Phản hồi mô phỏng nhận đơn không hợp lệ.');
      }
      return ActiveMechanicOrderDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ActiveMechanicOrderDto> confirmArrival(String orderId) async {
    try {
      final response = await _dioClient.dio.post(ApiEndpoints.mechanicOrderArrive(orderId));
      if (response.data is! Map) {
        throw const FormatException('Phản hồi thông tin đến nơi không hợp lệ.');
      }
      return ActiveMechanicOrderDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ActiveMechanicOrderDto> startRepair(String orderId) async {
    try {
      final response = await _dioClient.dio.post(ApiEndpoints.mechanicOrderStartRepair(orderId));
      if (response.data is! Map) {
        throw const FormatException('Phản hồi bắt đầu sửa chữa không hợp lệ.');
      }
      return ActiveMechanicOrderDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> saveQuote(
    String orderId, {
    required List<OrderQuoteLinePayload> lines,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        ApiEndpoints.mechanicOrderQuote(orderId),
        data: {
          'lines': lines.map((e) => e.toJson()).toList(),
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> completeRepair(
    String orderId, {
    required List<OrderQuoteLinePayload> lines,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicCompleteRepair(orderId),
        data: {
          if (lines.isNotEmpty) 'lines': lines.map((e) => e.toJson()).toList(),
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> settleCashOrder(String orderId, double amount) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicSettleCash(orderId),
        data: {
          'amount': amount,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
