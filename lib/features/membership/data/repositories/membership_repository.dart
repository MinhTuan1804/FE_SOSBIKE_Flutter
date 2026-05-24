import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';

class MembershipRepository {
  const MembershipRepository(this._dioClient);

  final DioClient _dioClient;

  Future<List<CustomerMembershipPlan>> getPlans() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.membershipPlans);
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => CustomerMembershipPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSubscription?> getCurrentSubscription() async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.currentMembership,
        options: Options(extra: {'skipAuthLogout': true}),
      );
      if (response.data == null) return null;
      if (response.data is! Map) return null;
      return CustomerSubscription.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSubscription> subscribe({
    required int planId,
    required bool autoRenew,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.subscribeMembership,
        data: {
          'planId': planId,
          'autoRenew': autoRenew,
        },
      );
      return CustomerSubscription.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSubscription> cancelRenewal() async {
    try {
      final response = await _dioClient.dio.patch(ApiEndpoints.cancelMembershipRenewal);
      return CustomerSubscription.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerPaymentIntent> createPaymentIntent({
    required int planId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.paymentIntents,
        data: {
          'purpose': 'SUBSCRIPTION',
          'method': paymentMethod,
          'planId': planId,
        },
      );

      if (response.data is! Map) {
        throw const FormatException('Payment intent response is invalid.');
      }

      return CustomerPaymentIntent.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSubscription> confirmPayment({
    required String paymentId,
    required bool autoRenew,
  }) async {
    try {
      await _dioClient.dio.post(
        '${ApiEndpoints.payments}/$paymentId/confirm',
        data: {
          'gatewayTransactionId': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
          'autoRenew': autoRenew,
        },
      );
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        throw const FormatException('Subscription was not created after payment confirmation.');
      }
      return subscription;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetTestSubscription() async {
    try {
      await _dioClient.dio.delete(ApiEndpoints.resetMembershipTest);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSubscription> createPaymentAndSubscribe({
    required int planId,
    required bool autoRenew,
    required String paymentMethod,
  }) async {
    try {
      final intent = await createPaymentIntent(
        planId: planId,
        paymentMethod: paymentMethod,
      );
      return await confirmPayment(
        paymentId: intent.paymentId,
        autoRenew: autoRenew,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CustomerSubscription> testPaymentAndSubscribe({
    required int planId,
    required bool autoRenew,
  }) {
    return createPaymentAndSubscribe(
      planId: planId,
      autoRenew: autoRenew,
      paymentMethod: 'BANK_TRANSFER',
    );
  }
}
