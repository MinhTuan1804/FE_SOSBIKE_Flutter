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
}
