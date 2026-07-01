import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';

class CustomerReviewRepository {
  const CustomerReviewRepository(this._dioClient);

  final DioClient _dioClient;

  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.reviews,
        data: {
          'orderId': orderId,
          'rating': rating,
          'comment': comment,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
