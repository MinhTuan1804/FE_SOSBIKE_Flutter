import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_customer_history_page.dart';

class MechanicHistoryRepository {
  const MechanicHistoryRepository(this._dioClient);

  final DioClient _dioClient;

  Future<MechanicCustomerHistoryPage> getCustomerHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.mechanicCustomerHistory,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (startDate != null)
            'startDate': startDate.toUtc().toIso8601String(),
          if (endDate != null)
            'endDate': endDate.toUtc().toIso8601String(),
        },
      );
      if (response.data is! Map) {
        throw const FormatException('History response is invalid.');
      }
      return MechanicCustomerHistoryPage.fromJson(
          Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
