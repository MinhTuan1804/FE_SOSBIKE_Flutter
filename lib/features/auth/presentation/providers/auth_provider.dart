import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:fe_moblie_flutter/core/network/error_message.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/features/auth/domain/mechanic_register_draft.dart';
import 'package:fe_moblie_flutter/features/auth/data/models/auth_models.dart';
import 'package:fe_moblie_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fe_moblie_flutter/features/profile/data/models/user_profile_models.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _avatarUrl;
  UserProfileDto? _profile;
  String? _verificationId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get authReady => _authReady;
  UserResponseDto? get user => _user;
  String get displayName => _displayName ?? _user?.fullName ?? 'Khách hàng';
  String? get avatarUrl => _avatarUrl ?? _user?.avatarUrl;
  UserProfileDto? get profile => _profile;

  String? _userType;
  String? get userType => _userType ?? _user?.userType;
  
  String? get phoneNumber => _profile?.phoneNumber ?? _user?.phoneNumber;
  String? get email => _profile?.email ?? _user?.email;
  String? get currentAddress => _profile?.currentAddress ?? _user?.currentAddress;
  String? get gender => _profile?.gender ?? _user?.gender;
  
  /// Ngày sinh dạng 'dd/MM/yyyy', hoặc null nếu chưa có.
  String? get dateOfBirth {
    final dob = _profile?.dateOfBirth;
    if (dob != null) {
      return '${dob.day.toString().padLeft(2, '0')}/'
          '${dob.month.toString().padLeft(2, '0')}/'
          '${dob.year}';
    }
    final dobUserStr = _user?.dateOfBirth;
    if (dobUserStr != null && dobUserStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(dobUserStr);
        return '${parsed.day.toString().padLeft(2, '0')}/'
            '${parsed.month.toString().padLeft(2, '0')}/'
            '${parsed.year}';
      } catch (_) {}
      return dobUserStr;
    }
    return null;
  }
  
  /// Xác thực SĐT — hiện chưa theo dõi từ BE, mặc định true khi đã đăng nhập.
  bool get isPhoneVerified => _isAuthenticated;
  bool get isActive => (_user?.isActive == true);

  /// Tránh kẹt màn trắng nếu secure storage / token check không trả về.
  void forceAuthReady() {
    if (_authReady) return;
    _authReady = true;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.hasToken();
    if (_isAuthenticated) {
      _displayName = await _authService.getUserName();
      _userType = await _authService.getUserType();
      _avatarUrl = await _authService.getAvatarUrl();
      
      // Fetch full profile data so ProfileScreen shows real info even after app restart
      try {
        _user = await _repository.getMine();
        _displayName = _user?.fullName ?? _displayName;
        _userType = _user?.userType ?? _userType;
        _avatarUrl = _user?.avatarUrl ?? _avatarUrl;
        
        _profile = await _repository.getMyProfile();
      } catch (e) {
        debugPrint('AuthProvider.checkAuthStatus getMine error: $e');
      }
    }
    _authReady = true;
    notifyListeners();
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _authService.saveToken(response.accessToken);
    if (response.refreshToken != null) {
      await _authService.saveRefreshToken(response.refreshToken!);
    }
    await _authService.saveUserName(response.user.fullName);
    await _authService.saveUserType(response.user.userType);
    await _authService.saveAvatarUrl(response.user.avatarUrl);
    _isAuthenticated = true;
    _authReady = true;
    _user = response.user;
    _displayName = response.user.fullName;
    _userType = response.user.userType;
    _avatarUrl = response.user.avatarUrl;
    
    // Also fetch the extended profile right after login so getters relying on _profile work
    try {
      _profile = await _repository.getMyProfile();
    } catch (_) {}
  }

  /// `null` = lỗi mạng/API; `true`/`false` = kết quả kiểm tra SĐT.
  Future<bool?> checkPhoneExists(String phoneNumber) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final exists = await _repository.checkPhoneExists(phoneNumber);
      return exists;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return null;
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
    if (kIsWeb || Firebase.apps.isEmpty) {
      onError('Firebase SMS không khả dụng trên web. Dùng mật khẩu hoặc OTP BE.');
      return;
    }

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
      _errorMessage = errorMessageFrom(e);
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
      _errorMessage = errorMessageFrom(e);
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
      _errorMessage = errorMessageFrom(e);
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
      _errorMessage = errorMessageFrom(e);
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
    String? identityCard,
    String? licensePlate,
    String? vehicleModel,
    String? vehicleGeneration,
    String? driverLicenseNumber,
    String? currentAddress,
    DateTime? dateOfBirth,
    String? bankCode,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
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
        // identityCard: identityCard,
        // licensePlate: licensePlate,
        // vehicleModel: vehicleModel,
        // vehicleGeneration: vehicleGeneration,
        // driverLicenseNumber: driverLicenseNumber,
        currentAddress: currentAddress,
        dateOfBirth: dateOfBirth,
        // bankCode: bankCode,
        // bankName: bankName,
        // bankAccountNumber: bankAccountNumber,
        // bankAccountHolder: bankAccountHolder,
      );
      await _persistSession(response);
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.register error: $e\n$st');
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin cơ bản (Họ tên, Ngày sinh, Giới tính, Email, Mã giới thiệu, Avatar, Địa chỉ)
  /// sau khi đăng ký thành công hoặc từ màn hình Chỉnh sửa.
  Future<bool> updateProfile({
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    String? email,
    String? referralCode,
    String? currentAddress,
    File? avatarFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uploadedAvatarUrl = await _repository.updateProfile(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        email: email,
        referralCode: referralCode,
        currentAddress: currentAddress,
        avatarFile: avatarFile,
        oldAvatarUrl: _avatarUrl,
      );
      
      // Update local storage strings
      _displayName = fullName;
      await _authService.saveUserName(fullName);
      
      if (uploadedAvatarUrl != null) {
        _avatarUrl = uploadedAvatarUrl;
        await _authService.saveAvatarUrl(uploadedAvatarUrl);
      }

      // Re-fetch full user profile to sync everything (DOB, Gender, etc.)
      try {
        _user = await _repository.getMine();
      } catch (_) {}

      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.updateProfile error: $e\n$st');
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfileDto?> fetchMyProfile({bool silent = false}) async {
    if (!_isAuthenticated) return null;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final profile = await _repository.getMyProfile();
      _profile = profile;
      _displayName = profile.fullName;
      _avatarUrl = profile.avatarUrl;
      _userType = profile.userType;
      await _authService.saveUserName(profile.fullName);
      await _authService.saveUserType(profile.userType);
      await _authService.saveAvatarUrl(profile.avatarUrl);
      notifyListeners();
      return profile;
    } catch (e, st) {
      debugPrint('AuthProvider.fetchMyProfile error: $e\n$st');
      if (!silent) _errorMessage = errorMessageFrom(e);
      return null;
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveMyProfile({
    required String fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? email,
    String? currentAddress,
    String? licensePlate,
    String? vehicleModel,
    String? vehicleGeneration,
    String? driverLicenseNumber,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    XFile? avatarFile,
    String? avatarUrl,
    String? cccdFrontUrl,
    String? cccdBackUrl,
    String? certificateUrl,
    String? vehiclePhotoUrl,
    String? vehicleRegistrationUrl,
    String? vehicleInsuranceUrl,
    String? driverLicenseUrl,
    String? color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newAvatar = await _repository.updateMyProfile(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        email: email,
        currentAddress: currentAddress,
        licensePlate: licensePlate,
        vehicleModel: vehicleModel,
        vehicleGeneration: vehicleGeneration,
        driverLicenseNumber: driverLicenseNumber,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountHolder: bankAccountHolder,
        avatarFile: avatarFile,
        avatarUrl: avatarUrl,
        cccdFrontUrl: cccdFrontUrl,
        cccdBackUrl: cccdBackUrl,
        certificateUrl: certificateUrl,
        vehiclePhotoUrl: vehiclePhotoUrl,
        vehicleRegistrationUrl: vehicleRegistrationUrl,
        vehicleInsuranceUrl: vehicleInsuranceUrl,
        driverLicenseUrl: driverLicenseUrl,
        color: color,
      );
      if (newAvatar != null) {
        _avatarUrl = newAvatar;
        await _authService.saveAvatarUrl(newAvatar);
      } else if (avatarUrl != null) {
        _avatarUrl = avatarUrl;
        await _authService.saveAvatarUrl(avatarUrl);
      }
      _displayName = fullName;
      await _authService.saveUserName(fullName);

      await fetchMyProfile();
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.saveMyProfile error: $e\n$st');
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadFileToFirebase(File file, String folder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Người dùng chưa đăng nhập Firebase.');
    }

    final rawExt = file.path.contains('.') ? file.path.split('.').last : 'jpg';
    final ext = rawExt.toLowerCase() == 'jpg' ? 'jpeg' : rawExt.toLowerCase();
    final fileName = '${folder.replaceAll('/', '_')}_${DateTime.now().microsecondsSinceEpoch}_${file.path.hashCode}.$ext';
    final ref = FirebaseStorage.instance.ref().child('$folder/${user.uid}/$fileName');

    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return await ref.getDownloadURL();
  }

  Future<String?> sendWithdrawOtp(String phoneNumber) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final res = await _repository.sendOtp(phoneNumber, 'WITHDRAW');
      return res['debugCode'] as String? ?? 'sent';
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> verifyWithdrawOtp(String phoneNumber, String code) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final token = await _repository.verifyOtpCode(phoneNumber, code);
      return token;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setupMechanicProfile({
    required String province,
    required String district,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolder,
    XFile? portrait,
    XFile? cccdFront,
    XFile? cccdBack,
    XFile? certificate,
    String? vehicleModel,
    String? vehicleGeneration,
    String? licensePlate,
    String? driverLicenseNumber,
    XFile? vehiclePhoto,         // ảnh chụp thực của xe
    XFile? vehicleRegistration,
    XFile? vehicleInsurance,
    XFile? driverLicense,
    String? color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> uploads = [];
      if (portrait != null) {
        uploads.add({
          'file': File(portrait.path),
          'folder': 'avatars',
          'key': 'portrait',
        });
      }
      if (cccdFront != null) {
        uploads.add({
          'file': File(cccdFront.path),
          'folder': 'documents',
          'key': 'cccdFront',
        });
      }
      if (cccdBack != null) {
        uploads.add({
          'file': File(cccdBack.path),
          'folder': 'documents',
          'key': 'cccdBack',
        });
      }
      if (certificate != null) {
        uploads.add({
          'file': File(certificate.path),
          'folder': 'documents',
          'key': 'certificate',
        });
      }
      if (vehiclePhoto != null) {
        uploads.add({
          'file': File(vehiclePhoto.path),
          'folder': 'vehicles',
          'key': 'vehiclePhoto',
        });
      }
      if (vehicleRegistration != null) {
        uploads.add({
          'file': File(vehicleRegistration.path),
          'folder': 'documents',
          'key': 'vehicleRegistration',
        });
      }
      if (vehicleInsurance != null) {
        uploads.add({
          'file': File(vehicleInsurance.path),
          'folder': 'documents',
          'key': 'vehicleInsurance',
        });
      }
      if (driverLicense != null) {
        uploads.add({
          'file': File(driverLicense.path),
          'folder': 'documents',
          'key': 'driverLicense',
        });
      }

      final Map<String, String> uploadedUrls = {};
      if (uploads.isNotEmpty) {
        final results = await Future.wait(
          uploads.map((item) => uploadFileToFirebase(item['file'] as File, item['folder'] as String)),
        );
        for (int i = 0; i < uploads.length; i++) {
          final key = uploads[i]['key'] as String;
          uploadedUrls[key] = results[i];
        }
      }

      final portraitUrl = uploadedUrls['portrait'];
      final cccdFrontUrl = uploadedUrls['cccdFront'];
      final cccdBackUrl = uploadedUrls['cccdBack'];
      final certificateUrl = uploadedUrls['certificate'];
      final vehiclePhotoUrl = uploadedUrls['vehiclePhoto'];
      final vehicleRegistrationUrl = uploadedUrls['vehicleRegistration'];
      final vehicleInsuranceUrl = uploadedUrls['vehicleInsurance'];
      final driverLicenseUrl = uploadedUrls['driverLicense'];

      final address = '${district.trim()}, ${province.trim()}';

      final success = await saveMyProfile(
        fullName: displayName,
        currentAddress: address,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountHolder: bankAccountHolder,
        vehicleModel: vehicleModel,
        vehicleGeneration: vehicleGeneration,
        licensePlate: licensePlate,
        driverLicenseNumber: driverLicenseNumber,
        avatarUrl: portraitUrl,
        cccdFrontUrl: cccdFrontUrl,
        cccdBackUrl: cccdBackUrl,
        certificateUrl: certificateUrl,
        vehiclePhotoUrl: vehiclePhotoUrl,
        vehicleRegistrationUrl: vehicleRegistrationUrl,
        vehicleInsuranceUrl: vehicleInsuranceUrl,
        driverLicenseUrl: driverLicenseUrl,
        color: color,
      );

      return success;
    } catch (e, st) {
      debugPrint('setupMechanicProfile error: $e\n$st');
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadMechanicDocuments(MechanicRegisterDraft draft) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (draft.portraitFile != null) {
        final portraitUrl = await uploadFileToFirebase(File(draft.portraitFile!.path), 'avatars');
        await saveMyProfile(
          fullName: displayName,
          avatarUrl: portraitUrl,
        );
      }
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.uploadMechanicDocuments error: $e\n$st');
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    await _authService.deleteRefreshToken();
    await _authService.clearUserProfile();
    _isAuthenticated = false;
    _authReady = true;
    _user = null;
    _displayName = null;
    _avatarUrl = null;
    _profile = null;
    notifyListeners();
  }

  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendEmailVerification();
      return true;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
