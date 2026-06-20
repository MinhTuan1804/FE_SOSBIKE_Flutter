import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_service_offering_models.dart';

class MechanicServiceOfferingRepository {
  const MechanicServiceOfferingRepository(this._dioClient);

  final DioClient _dioClient;

  Future<List<MechanicServiceOfferingDto>> listMine() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.mechanicMyServices);
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Mechanic services response is invalid.');
      }
      return data
          .map((e) => MechanicServiceOfferingDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<MechanicServiceOfferingDto> create(CreateMechanicServicePayload payload) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.mechanicMyServices,
        data: payload.toJson(),
      );
      if (response.data is! Map) {
        throw const FormatException('Create mechanic service response is invalid.');
      }
      return MechanicServiceOfferingDto.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(int mechanicServiceId) async {
    try {
      await _dioClient.dio.delete(ApiEndpoints.mechanicMyService(mechanicServiceId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
