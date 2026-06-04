import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/home/data/models/blog_post_model.dart';
import 'package:fe_moblie_flutter/features/home/data/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository;

  HomeProvider(this._repository);

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
}
