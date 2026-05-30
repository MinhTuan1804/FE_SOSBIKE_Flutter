import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_priority_models.dart';

class MechanicSubscriptionRepository {
  const MechanicSubscriptionRepository(this._dioClient);

  final DioClient _dioClient;

  Future<MechanicCurrentSubscription> getSubscription() async {
    final response =
        await _dioClient.dio.get(ApiEndpoints.mechanicSubscription);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MechanicCurrentSubscription.fromJson(data);
    }
    return MechanicCurrentSubscription.empty;
  }
}
