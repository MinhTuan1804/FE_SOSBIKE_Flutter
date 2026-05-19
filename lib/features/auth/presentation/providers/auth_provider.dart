import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/features/auth/data/models/auth_models.dart';
import 'package:fe_moblie_flutter/features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final AuthService _authService;
  
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  AuthProvider(this._repository, this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _verificationId;

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

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Tự động xác thực trên Android nếu có thể
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = e.message ?? 'Xác thực số điện thoại thất bại';
          _isLoading = false;
          notifyListeners();
          onError(_errorMessage!);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      onError(_errorMessage!);
    }
  }

  Future<bool> verifyOtp(String smsCode, {String? fullName, String? userType}) async {
    if (_verificationId == null) {
      _errorMessage = 'Thiếu mã xác thực (Verification ID)';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _signInWithCredential(credential, fullName: fullName, userType: userType);
    } catch (e) {
      _errorMessage = 'Mã OTP không hợp lệ hoặc đã hết hạn';
      debugPrint('AuthProvider.verifyOtp error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _signInWithCredential(PhoneAuthCredential credential, {String? fullName, String? userType}) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Lấy Firebase ID Token
        final idToken = await user.getIdToken();
        if (idToken != null) {
          // Gọi Backend của chúng ta
          final response = await _repository.firebaseLogin(
            idToken,
            fullName: fullName,
            userType: userType,
          );
          // Lưu JWT Token nội bộ
          await _authService.saveToken(response.accessToken);
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống khi xác thực với backend';
      debugPrint('AuthProvider._signInWithCredential error: $e');
      return false;
    }
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
