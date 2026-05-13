import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final AuthService _authService;

  AuthProvider(this._repository, this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.hasToken();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.login(username, password);
      await _authService.saveToken(response.token);
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    _isAuthenticated = false;
    notifyListeners();
  }
}
