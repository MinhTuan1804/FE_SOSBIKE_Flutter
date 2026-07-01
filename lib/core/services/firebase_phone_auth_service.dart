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
    String formattedPhone = e164Phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+84$formattedPhone';
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
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
    final msg = e.message ?? '';
    if (msg.contains('BILLING_NOT_ENABLED') || e.code == 'billing-not-enabled') {
      return 'Firebase chưa bật thanh toán (Blaze) nên không gửi SMS thật.\n'
          'Cách 1 (dev): Authentication → Phone → thêm số test (+84..., mã 123456).\n'
          'Cách 2: Nâng project lên gói Blaze (thêm thẻ, vẫn có hạn mức miễn phí).';
    }
    if (e.code == 'missing-client-identifier' ||
        msg.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase chưa cấu hình OTP trên Android.\n'
          'Vào Firebase Console → project sosbike-7b6bb:\n'
          '1. Authentication → đăng nhập Phone → Bật\n'
          '2. Cài đặt dự án → app Android → thêm SHA-1 debug:\n'
          '   CC:08:A4:B6:28:2D:E8:0C:91:12:D0:C4:57:D7:38:D6:28:88:15:6B\n'
          '3. Tải lại google-services.json → thay file android/app/\n'
          '4. flutter clean && flutter run';
    }
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
