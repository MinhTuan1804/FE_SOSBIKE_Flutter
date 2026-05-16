import 'package:flutter/foundation.dart';
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

  Future<bool> login(String phoneNumber, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.login(phoneNumber, password);
      await _authService.saveToken(response.accessToken);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.login error: $e\n$st');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String userType,
    String? email,
    String? firebaseIdToken,
    String? otpToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.register(
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
        userType: userType,
        email: email,
        firebaseIdToken: firebaseIdToken,
        otpToken: otpToken,
      );
      await _authService.saveToken(response.accessToken);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.register error: $e\n$st');
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
