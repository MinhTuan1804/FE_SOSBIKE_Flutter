import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  AuthProvider(this._repository, this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _authReady = false;
  UserResponseDto? _user;
  String? _displayName;
  String? _avatarUrl;
  UserProfileDto? _profile;

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
  bool get isGoogleLinked => _profile?.isGoogleLinked ?? false;
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

  /// Đăng nhập Google qua Google Cloud Console OAuth → BE /GoogleAuth/login.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await _obtainGoogleIdToken();
      if (idToken == null) {
        return false;
      }

      final response = await _repository.googleLogin(idToken);
      await _persistSession(response);
      notifyListeners();
      return true;
    } catch (e, st) {
      _errorMessage = errorMessageFrom(e);
      debugPrint('AuthProvider.signInWithGoogle error: $e\n$st');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Liên kết Google với tài khoản đang đăng nhập (SĐT/mật khẩu).
  Future<bool> linkGoogleAccount() async {
    if (!_isAuthenticated) {
      _errorMessage = 'Bạn cần đăng nhập trước khi liên kết Google.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await _obtainGoogleIdToken();
      if (idToken == null) {
        return false;
      }

      await _repository.linkGoogle(idToken);
      await fetchMyProfile(silent: true);
      notifyListeners();
      return true;
    } catch (e, st) {
      _errorMessage = errorMessageFrom(e);
      debugPrint('AuthProvider.linkGoogleAccount error: $e\n$st');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _obtainGoogleIdToken() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleWebClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _errorMessage = 'Không lấy được Google ID token. Kiểm tra OAuth Client ID trên Google Cloud Console.';
        return null;
      }

      return idToken;
    } catch (e) {
      _errorMessage = errorMessageFrom(e);
      return null;
    }
  }

  static String? get _googleWebClientId {
    const fromDefine = String.fromEnvironment('GOOGLE_OAUTH_WEB_CLIENT_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    try {
      if (dotenv.isInitialized) {
        final fromEnv = dotenv.env['GOOGLE_OAUTH_WEB_CLIENT_ID']?.trim();
        if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
      }
    } catch (_) {}
    return null;
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
    XFile? avatarFile,
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
    XFile? cccdFrontFile,
    XFile? cccdBackFile,
    XFile? certificateFile,
    XFile? vehiclePhotoFile,
    XFile? vehicleRegistrationFile,
    XFile? vehicleInsuranceFile,
    XFile? driverLicenseFile,
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
        cccdFrontFile: cccdFrontFile,
        cccdBackFile: cccdBackFile,
        certificateFile: certificateFile,
        vehiclePhotoFile: vehiclePhotoFile,
        vehicleRegistrationFile: vehicleRegistrationFile,
        vehicleInsuranceFile: vehicleInsuranceFile,
        driverLicenseFile: driverLicenseFile,
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
      final address = '${district.trim()}, ${province.trim()}';

      return saveMyProfile(
        fullName: displayName,
        currentAddress: address,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountHolder: bankAccountHolder,
        vehicleModel: vehicleModel,
        vehicleGeneration: vehicleGeneration,
        licensePlate: licensePlate,
        driverLicenseNumber: driverLicenseNumber,
        avatarFile: portrait,
        cccdFrontFile: cccdFront,
        cccdBackFile: cccdBack,
        certificateFile: certificate,
        vehiclePhotoFile: vehiclePhoto,
        vehicleRegistrationFile: vehicleRegistration,
        vehicleInsuranceFile: vehicleInsurance,
        driverLicenseFile: driverLicense,
        color: color,
      );
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
        return saveMyProfile(
          fullName: displayName,
          avatarFile: draft.portraitFile,
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
