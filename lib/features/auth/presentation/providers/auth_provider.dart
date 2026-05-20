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
  String get displayName => _displayName ?? _user?.fullName ?? 'KhÃ¡ch hÃ ng';

  String? _userType;
  String? get userType => _userType ?? _user?.userType;

  /// TrÃ¡nh káº¹t mÃ n tráº¯ng náº¿u secure storage / token check khÃ´ng tráº£ vá».
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
      _errorMessage = 'Lá»—i khi kiá»ƒm tra sá»‘ Ä‘iá»‡n thoáº¡i: ${e.toString()}';
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
          // Tá»± Ä‘á»™ng xÃ¡c thá»±c trÃªn Android náº¿u cÃ³ thá»ƒ
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _errorMessage = e.message ?? 'XÃ¡c thá»±c sá»‘ Ä‘iá»‡n thoáº¡i tháº¥t báº¡i';
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
      _errorMessage = 'Thiáº¿u mÃ£ xÃ¡c thá»±c (Verification ID)';
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
      _errorMessage = 'MÃ£ OTP khÃ´ng há»£p lá»‡ hoáº·c Ä‘Ã£ háº¿t háº¡n';
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
        // Láº¥y Firebase ID Token
        final idToken = await user.getIdToken();
        if (idToken != null) {

          if (isRegister) {
            // KHÃ”NG Gá»ŒI API ÄÄ‚NG KÃ (REGISTER) NGAY LÃšC NÃ€Y Ná»®A
            // Chá»‰ tráº£ vá» true Ä‘á»ƒ cho phÃ©p qua mÃ n hÃ¬nh OTP -> Profile Setup.
            // Profile Setup sáº½ gá»i API Register sau.
            return true;
          } else {
             // Gá»i Backend API ÄÄƒng nháº­p Firebase (Login)
             final response = await _repository.firebaseLogin(
               idToken,
               fullName: null, // Báº¯t buá»™c null Ä‘á»ƒ Backend hiá»ƒu lÃ  Login
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
         // TrÃ­ch xuáº¥t message tá»« BE tráº£ vá» (vÃ­ dá»¥: Sá»‘ Ä‘iá»‡n thoáº¡i chÆ°a Ä‘Æ°á»£c Ä‘Äƒng kÃ½...)
         _errorMessage = e.toString();
       } else {
         _errorMessage = 'Lá»—i há»‡ thá»‘ng khi xÃ¡c thá»±c vá»›i backend';
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

  /// Cáº­p nháº­t thÃ´ng tin cÆ¡ báº£n (Há» tÃªn, NgÃ y sinh, Giá»›i tÃ­nh, Email, MÃ£ giá»›i thiá»‡u, Avatar)
  /// sau khi Ä‘Äƒng kÃ½ thÃ nh cÃ´ng.
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
