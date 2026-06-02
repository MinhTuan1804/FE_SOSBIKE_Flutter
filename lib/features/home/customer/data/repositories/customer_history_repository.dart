import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/models/customer_order_history_page.dart';

class CustomerHistoryRepository {
  const CustomerHistoryRepository(this._dioClient);

  final DioClient _dioClient;

  Future<CustomerOrderHistoryPage> getOrderHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.customerOrderHistory,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return CustomerOrderHistoryPage.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
