import '../models/post_model.dart';

class HomeRepository {
  HomeRepository();

  Future<List<PostModel>> getPosts() async {
    // BE hiện không có /posts — tránh 404 khi mở Home sau đăng nhập.
    await Future<void>.delayed(Duration.zero);
    return [];
  }
}
