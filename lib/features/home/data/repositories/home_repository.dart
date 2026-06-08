import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/home/data/models/blog_post_model.dart';

class HomeRepository {
  final DioClient _dioClient;

  HomeRepository(this._dioClient);

  Future<List<BlogPostModel>> getPosts() async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.blogs,
      queryParameters: {
        'page': 1,
        'pageSize': 10,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((item) => BlogPostModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return items;
  }

  Future<void> trackBlogView({
    required String slug,
    required String visitorId,
    required String source,
    String? referrerUrl,
    String? userAgent,
  }) async {
    await _dioClient.dio.post(
      ApiEndpoints.blogTrackView(slug),
      data: {
        'source': source,
        'visitorId': visitorId,
        if (referrerUrl != null) 'referrerUrl': referrerUrl,
        if (userAgent != null) 'userAgent': userAgent,
      },
    );
  }
}
