import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';

class MechanicWalletRepository {
  const MechanicWalletRepository(this._dioClient);

  final DioClient _dioClient;

  Future<MechanicWalletData> getWallet({
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      final response = await _dioClient.dio.get(
        ApiEndpoints.mechanicWallet,
        queryParameters: queryParams,
      );
      if (response.data is! Map) {
        throw const FormatException('Phản hồi thông tin ví không hợp lệ.');
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

  Future<Map<String, dynamic>> withdraw(int amount, {String? description, String? otpToken}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicWalletWithdraw,
        data: {
          'amount': amount,
          if (description != null && description.isNotEmpty) 'description': description,
          if (otpToken != null && otpToken.isNotEmpty) 'otpToken': otpToken,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({bool hasWallet, bool hasPin})> checkPinStatus() async {
    try {
      final response = await _dioClient.dio.get('/wallet/pin-status');
      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return (
          hasWallet: map['hasWallet'] == true,
          hasPin: map['hasPin'] == true,
        );
      }
      return (hasWallet: true, hasPin: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return (hasWallet: false, hasPin: false);
      }
      throw ApiException.fromDioError(e);
    }
  }

  Future<MechanicWalletData> createWallet() async {
    try {
      final response = await _dioClient.dio.post(ApiEndpoints.mechanicWallet);
      if (response.data is! Map) {
        throw const FormatException('Phản hồi tạo ví không hợp lệ.');
      }
      return MechanicWalletData.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> setupPin(String pin) async {
    try {
      await _dioClient.dio.post(
        '/wallet/setup-pin',
        data: {'pin': pin},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final response = await _dioClient.dio.post(
        '/wallet/verify-pin',
        data: {'pin': pin},
      );
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
