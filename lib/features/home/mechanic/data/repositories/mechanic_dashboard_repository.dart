import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_dashboard_models.dart';

class MechanicDashboardRepository {
  const MechanicDashboardRepository(this._dioClient);

  final DioClient _dioClient;

  Future<MechanicDashboardData> getDashboard() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.mechanicDashboard);
      if (response.data is! Map) {
        throw const FormatException('Dashboard response is invalid.');
      }
      return MechanicDashboardData.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
