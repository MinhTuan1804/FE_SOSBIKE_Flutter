import 'dart:io';
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
  bool _authReady = false;
  UserResponseDto? _user;
  String? _displayName;
  String? _verificationId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get authReady => _authReady;
  UserResponseDto? get user => _user;
  String get displayName => _displayName ?? _user?.fullName ?? 'Khách hàng';

  String? _userType;
  String? get userType => _userType ?? _user?.userType;

  /// Tránh kẹt màn trắng nếu secure storage / token check không trả về.
  void forceAuthReady() {
    if (_authReady) return;
    _authReady = true;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.hasToken();
    if (_isAuthenticated) {
      _displayName = await _authService.getUserName();
      _userType = await _authService.getUserType();
    }
    _authReady = true;
    notifyListeners();
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _authService.saveToken(response.accessToken);
    await _authService.saveUserName(response.user.fullName);
    await _authService.saveUserType(response.user.userType);
    _isAuthenticated = true;
    _user = response.user;
    _displayName = response.user.fullName;
    _userType = response.user.userType;
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final exists = await _repository.checkPhoneExists(phoneNumber);
      return exists;
    } catch (e) {
      _errorMessage = 'Lỗi khi kiểm tra số điện thoại: ${e.toString()}';
      return false; // Safely return false or handle otherwise
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<bool> verifyOtp(String smsCode, {String? fullName, String? userType, required bool isRegister}) async {
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
      return await _signInWithCredential(credential, fullName: fullName, userType: userType, isRegister: isRegister);
    } catch (e) {
      _errorMessage = 'Mã OTP không hợp lệ hoặc đã hết hạn';
      debugPrint('AuthProvider.verifyOtp error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _signInWithCredential(PhoneAuthCredential credential, {String? fullName, String? userType, bool isRegister = false}) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Lấy Firebase ID Token
        final idToken = await user.getIdToken();
        if (idToken != null) {

          if (isRegister) {
            // KHÔNG GỌI API ĐĂNG KÝ (REGISTER) NGAY LÚC NÀY NỮA
            // Chỉ trả về true để cho phép qua màn hình OTP -> Profile Setup.
            // Profile Setup sẽ gọi API Register sau.
            return true;
          } else {
             // Gọi Backend API Đăng nhập Firebase (Login)
             final response = await _repository.firebaseLogin(
               idToken,
               fullName: null, // Bắt buộc null để Backend hiểu là Login
               userType: userType,
            );
            await _persistSession(response);
          }

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
       if (e.toString().contains('DioException')) {
         // Trích xuất message từ BE trả về (ví dụ: Số điện thoại chưa được đăng ký...)
         _errorMessage = e.toString();
       } else {
         _errorMessage = 'Lỗi hệ thống khi xác thực với backend';
       }
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

  /// Cập nhật thông tin cơ bản (Họ tên, Ngày sinh, Giới tính, Email, Mã giới thiệu, Avatar)
  /// sau khi đăng ký thành công.
  Future<bool> updateProfile({
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    String? email,
    String? referralCode,
    File? avatarFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.updateProfile(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        email: email,
        referralCode: referralCode,
        avatarFile: avatarFile,
      );
      if (success) {
        _displayName = fullName;
      }
      return success;
    } catch (e, st) {
      debugPrint('AuthProvider.updateProfile error: $e\n$st');
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
