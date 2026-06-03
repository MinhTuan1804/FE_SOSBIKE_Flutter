import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';

class MechanicWalletRepository {
  const MechanicWalletRepository(this._dioClient);

  final DioClient _dioClient;

  Future<MechanicWalletData> getWallet({int limit = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.mechanicWallet,
        queryParameters: {'limit': limit},
      );
      if (response.data is! Map) {
        throw const FormatException('Wallet response is invalid.');
      }
      return MechanicWalletData.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(int amount) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.paymentIntents,
        data: {
          'amount': amount,
          'method': 'BANK_TRANSFER',
          'purpose': 'WALLET_DEPOSIT',
        },
      );
      final raw = Map<String, dynamic>.from(response.data);
      // Normalize fields từ camelCase API response
      return {
        'paymentId': (raw['paymentId'] ?? raw['PaymentId'])?.toString(),
        'paymentCode': (raw['paymentCode'] ?? raw['PaymentCode'])?.toString(),
        'qrContent': (raw['qrContent'] ?? raw['QrContent'])?.toString(),
        'checkoutUrl': (raw['checkoutUrl'] ?? raw['CheckoutUrl'])?.toString(),
        'bankBin': (raw['bankBin'] ?? raw['BankBin'])?.toString(),
        'bankAccountNumber': (raw['bankAccountNumber'] ?? raw['BankAccountNumber'])?.toString(),
        'bankAccountName': (raw['bankAccountName'] ?? raw['BankAccountName'])?.toString(),
        'status': (raw['status'] ?? raw['Status'])?.toString(),
        'amount': raw['amount'] ?? raw['Amount'],
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiEndpoints.payments}/$paymentId',
      );
      final raw = Map<String, dynamic>.from(response.data);
      // Normalize để đảm bảo key 'status' luôn có giá trị
      return {
        ...raw,
        'status': (raw['status'] ?? raw['Status'])?.toString(),
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> deposit(int amount, {String? description}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicWalletDeposit,
        data: {
          'amount': amount,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> withdraw(int amount, {String? description}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicWalletWithdraw,
        data: {
          'amount': amount,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
