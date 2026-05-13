import 'package:dio/dio.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import '../models/post_model.dart';

class HomeRepository {
  final DioClient _dioClient;

  HomeRepository(this._dioClient);

  Future<List<PostModel>> getPosts() async {
    try {
      final response = await _dioClient.dio.get('/posts'); // Giả sử BE có endpoint /posts
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => PostModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
