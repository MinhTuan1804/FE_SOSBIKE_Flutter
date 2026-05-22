import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/network/api_exceptions.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
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
      final response = await _dioClient.dio.get('/users/mine');
      return UserResponseDto.fromJson(response.data);
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
    String? referralCode,
    File? avatarFile,
    String? oldAvatarUrl,
  }) async {
    try {
      final uploadedAvatarUrl =
          avatarFile != null ? await _uploadAvatarToFirebase(avatarFile, oldAvatarUrl) : null;
      final formData = FormData.fromMap({
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        if (email != null) 'email': email,
        if (referralCode != null) 'referralCode': referralCode,
        if (uploadedAvatarUrl != null) 'avatarUrl': uploadedAvatarUrl,
      });

      await _dioClient.dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
      );
      return uploadedAvatarUrl;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> _uploadAvatarToFirebase(File avatarFile, String? oldAvatarUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Người dùng chưa đăng nhập Firebase.');
    }

    final rawExt = avatarFile.path.contains('.')
        ? avatarFile.path.split('.').last
        : 'jpg';
    final ext = rawExt.toLowerCase() == 'jpg' ? 'jpeg' : rawExt.toLowerCase();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}/$fileName');

    await ref.putFile(
      avatarFile,
      SettableMetadata(contentType: 'image/$ext'),
    );
    final newUrl = await ref.getDownloadURL();

    if (_isFirebaseStorageUrl(oldAvatarUrl) && oldAvatarUrl != newUrl) {
      final oldRef = FirebaseStorage.instance.refFromURL(oldAvatarUrl!);
      await oldRef.delete();
    }

    return newUrl;
  }

  bool _isFirebaseStorageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('gs://') || url.contains('firebasestorage.googleapis.com');
  }
}
