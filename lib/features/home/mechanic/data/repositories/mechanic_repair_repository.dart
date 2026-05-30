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
        throw const FormatException('Repair services response is invalid.');
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
        throw const FormatException('Spare parts response is invalid.');
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
        throw const FormatException('Active order response is invalid.');
      }
      return ActiveMechanicOrderDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> saveQuote(
    String orderId, {
    required List<OrderQuoteLinePayload> lines,
    String? mechanicNote,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        ApiEndpoints.mechanicOrderQuote(orderId),
        data: {
          'lines': lines.map((e) => e.toJson()).toList(),
          if (mechanicNote != null && mechanicNote.isNotEmpty) 'mechanicNote': mechanicNote,
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
    String? mechanicNote,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicCompleteRepair(orderId),
        data: {
          if (lines.isNotEmpty) 'lines': lines.map((e) => e.toJson()).toList(),
          if (mechanicNote != null && mechanicNote.isNotEmpty) 'mechanicNote': mechanicNote,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
