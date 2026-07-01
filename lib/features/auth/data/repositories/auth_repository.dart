import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/features/profile/data/models/user_profile_models.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> login(String phoneNumber, String password) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: LoginRequest(phoneNumber: phoneNumber, password: password).toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> firebaseLogin(String idToken, {String? fullName, String? userType}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.firebaseLogin,
        data: {
          'idToken': idToken,
          if (fullName != null) 'fullName': fullName,
          if (userType != null) 'userType': userType,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String userType,
    String? email,
    String? firebaseIdToken,
    String? otpToken,
    String? currentAddress,
    DateTime? dateOfBirth,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.register,
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
          'fullName': fullName,
          'userType': userType,
          if (email != null) 'email': email,
          if (firebaseIdToken != null) 'firebaseIdToken': firebaseIdToken,
          if (otpToken != null) 'otpToken': otpToken,
          if (currentAddress != null) 'currentAddress': currentAddress,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.checkPhone,
        queryParameters: {'phoneNumber': phoneNumber},
      );
      return response.data['exists'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserResponseDto> getMine() async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.userMe,
      );
      return UserResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserProfileDto> getMyProfile() async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.userMe,
      );
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Cập nhật hồ sơ (text + avatar tùy chọn).
  Future<String?> updateMyProfile({
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
    try {
      final formData = FormData.fromMap({
        'fullName': fullName,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
        if (gender != null) 'gender': gender,
        if (email != null) 'email': email,
        if (currentAddress != null) 'currentAddress': currentAddress,
        if (licensePlate != null) 'licensePlate': licensePlate,
        if (vehicleModel != null) 'vehicleModel': vehicleModel,
        if (vehicleGeneration != null) 'vehicleGeneration': vehicleGeneration,
        if (driverLicenseNumber != null) 'driverLicenseNumber': driverLicenseNumber,
        if (bankName != null) 'bankName': bankName,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (bankAccountHolder != null) 'bankAccountHolder': bankAccountHolder,
        if (avatarFile != null) 'avatar': await _multipartFromXFile(avatarFile, 'avatar.jpg'),
        if (cccdFrontFile != null) 'cccdFront': await _multipartFromXFile(cccdFrontFile, 'cccd_front.jpg'),
        if (cccdBackFile != null) 'cccdBack': await _multipartFromXFile(cccdBackFile, 'cccd_back.jpg'),
        if (certificateFile != null) 'certificate': await _multipartFromXFile(certificateFile, 'certificate.jpg'),
        if (vehiclePhotoFile != null) 'vehiclePhoto': await _multipartFromXFile(vehiclePhotoFile, 'vehicle.jpg'),
        if (vehicleRegistrationFile != null)
          'vehicleRegistration': await _multipartFromXFile(vehicleRegistrationFile, 'registration.jpg'),
        if (vehicleInsuranceFile != null)
          'vehicleInsurance': await _multipartFromXFile(vehicleInsuranceFile, 'insurance.jpg'),
        if (driverLicenseFile != null) 'driverLicense': await _multipartFromXFile(driverLicenseFile, 'license.jpg'),
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (cccdFrontUrl != null) 'cccdFrontUrl': cccdFrontUrl,
        if (cccdBackUrl != null) 'cccdBackUrl': cccdBackUrl,
        if (certificateUrl != null) 'certificateUrl': certificateUrl,
        if (vehiclePhotoUrl != null) 'vehiclePhotoUrl': vehiclePhotoUrl,
        if (vehicleRegistrationUrl != null) 'vehicleRegistrationUrl': vehicleRegistrationUrl,
        if (vehicleInsuranceUrl != null) 'vehicleInsuranceUrl': vehicleInsuranceUrl,
        if (driverLicenseUrl != null) 'driverLicenseUrl': driverLicenseUrl,
        if (color != null) 'color': color,
      });

      final response = await _dioClient.dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
      );
      final data = response.data;
      if (data is Map && data['avatarUrl'] != null) {
        return data['avatarUrl'] as String;
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
  /// Cập nhật thông tin cơ bản sau đăng ký.
  Future<String?> updateProfile({
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    String? email,
    String? currentAddress,
    String? referralCode,
    XFile? avatarFile,
    String? oldAvatarUrl,
  }) async {
    try {
      final formData = FormData.fromMap({
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        if (email != null) 'email': email,
        if (currentAddress != null) 'currentAddress': currentAddress,
        if (referralCode != null) 'referralCode': referralCode,
        if (avatarFile != null) 'avatar': await _multipartFromXFile(avatarFile, 'avatar.jpg'),
      });

      final response = await _dioClient.dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
      );
      final data = response.data;
      if (data is Map && data['avatarUrl'] != null) {
        return data['avatarUrl'] as String;
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> uploadAvatarToFirebase(XFile avatarFile, String? oldAvatarUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Người dùng chưa đăng nhập Firebase.');
    }

    final rawExt = avatarFile.name.contains('.') ? avatarFile.name.split('.').last : 'jpg';
    final ext = rawExt.toLowerCase() == 'jpg' ? 'jpeg' : rawExt.toLowerCase();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}/$fileName');
    final bytes = await avatarFile.readAsBytes();

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$ext'),
    );
    final newUrl = await ref.getDownloadURL();

    if (isFirebaseStorageUrl(oldAvatarUrl) && oldAvatarUrl != newUrl) {
      try {
        final oldRef = FirebaseStorage.instance.refFromURL(oldAvatarUrl!);
        await oldRef.delete();
      } catch (_) {
        // ignore delete errors
      }
    }

    return newUrl;
  }

  bool isFirebaseStorageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('gs://') || url.contains('firebasestorage.googleapis.com');
  }

  Future<void> uploadMechanicDocuments({
    XFile? portrait,
    XFile? vehicleRegistration,
    XFile? vehicleInsurance,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (portrait != null) 'portrait': await _multipartFromXFile(portrait, 'portrait.jpg'),
        if (vehicleRegistration != null)
          'vehicleRegistration': await _multipartFromXFile(vehicleRegistration, 'registration.jpg'),
        if (vehicleInsurance != null)
          'vehicleInsurance': await _multipartFromXFile(vehicleInsurance, 'insurance.jpg'),
      });

      await _dioClient.dio.put(
        ApiEndpoints.mechanicDocuments,
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  static Future<MultipartFile> _multipartFromXFile(XFile file, String fallbackName) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : fallbackName;
    return MultipartFile.fromBytes(bytes, filename: name);
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber, String purpose) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.sendOtp,
        data: {'phoneNumber': phoneNumber, 'purpose': purpose},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> verifyOtpCode(String phoneNumber, String code) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: {'phoneNumber': phoneNumber, 'code': code},
      );
      return response.data['otpToken'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _dioClient.dio.post(ApiEndpoints.sendEmailVerification);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
