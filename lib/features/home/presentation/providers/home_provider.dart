import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/features/home/data/models/blog_post_model.dart';
import 'package:fe_moblie_flutter/features/home/data/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider(this._repository, this._authService);

  final HomeRepository _repository;
  final AuthService _authService;

  List<BlogPostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BlogPostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _repository.getPosts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> trackBlogView(String slug) async {
    try {
      final visitorId = await _authService.getOrCreateBlogVisitorId();
      await _repository.trackBlogView(
        slug: slug,
        visitorId: visitorId,
        source: 'APP',
      );

      final index = _posts.indexWhere((p) => p.slug == slug);
      if (index != -1) {
        final currentPost = _posts[index];
        _posts[index] = currentPost.copyWith(
          viewCount: (currentPost.viewCount ?? 0) + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('HomeProvider.trackBlogView error: $e');
    }
  }
}
