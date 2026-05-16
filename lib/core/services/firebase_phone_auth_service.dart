import 'package:firebase_auth/firebase_auth.dart';

/// Gửi / xác minh OTP đăng ký qua Firebase Phone Auth.
class FirebasePhoneAuthService {
  String? _verificationId;
  int? _resendToken;

  bool get hasVerificationId => _verificationId != null;

  Future<void> sendOtp(
    String e164Phone, {
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    bool resend = false,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resend ? _resendToken : null,
      verificationCompleted: (credential) {
        onAutoVerified?.call(credential);
      },
      verificationFailed: (e) {
        onError(_mapError(e));
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifySmsCode(String smsCode) async {
    final id = _verificationId;
    if (id == null) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'Chưa gửi mã OTP. Vui lòng thử gửi lại.',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: id,
      smsCode: smsCode,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Sau khi xác minh SĐT, thoát session Firebase (app dùng JWT của BE).
  Future<void> signOutFirebase() async {
    await FirebaseAuth.instance.signOut();
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ.';
      case 'too-many-requests':
        return 'Gửi OTP quá nhiều lần. Thử lại sau.';
      case 'quota-exceeded':
        return 'Hết hạn mức SMS. Kiểm tra gói Firebase Blaze.';
      case 'invalid-verification-code':
        return 'Mã OTP không đúng.';
      case 'session-expired':
        return 'Mã OTP đã hết hạn. Gửi lại mã mới.';
      default:
        return e.message ?? 'Lỗi xác thực Firebase (${e.code})';
    }
  }
}
