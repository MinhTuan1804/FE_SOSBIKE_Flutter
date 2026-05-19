import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/features/auth/data/models/auth_models.dart';
import 'package:fe_moblie_flutter/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final AuthService _authService;

  AuthProvider(this._repository, this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _authReady = false;
  UserResponseDto? _user;
  String? _displayName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get authReady => _authReady;
  UserResponseDto? get user => _user;
  String get displayName => _displayName ?? _user?.fullName ?? 'Khách hàng';

  /// Tránh kẹt màn trắng nếu secure storage / token check không trả về.
  void forceAuthReady() {
    if (_authReady) return;
    _authReady = true;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      _isAuthenticated = await _authService.hasValidToken().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
      if (_isAuthenticated) {
        _displayName = await _authService.getUserName().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      } else {
        _displayName = null;
        _user = null;
      }
    } catch (e, st) {
      debugPrint('AuthProvider.checkAuthStatus error: $e\n$st');
      _isAuthenticated = false;
      _displayName = null;
      _user = null;
    } finally {
      _authReady = true;
      notifyListeners();
    }
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _authService.saveToken(response.accessToken);
    await _authService.saveUserName(response.user.fullName);
    _user = response.user;
    _displayName = response.user.fullName;
    _isAuthenticated = true;
  }

  Future<bool> login(String phoneNumber, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.login(phoneNumber, password);
      await _persistSession(response);
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
      await _persistSession(response);
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
    await _authService.clearUserProfile();
    _isAuthenticated = false;
    _user = null;
    _displayName = null;
    notifyListeners();
  }
}
