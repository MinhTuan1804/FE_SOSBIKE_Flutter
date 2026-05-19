class ApiEndpoints {
  /// BE deploy (nginx) — HTTP. Emulator local: `http://10.0.2.2:<port>/api`; máy thật: IP LAN hoặc URL này.
  static const String baseUrl = 'https://finlike-lorrie-refreshfully.ngrok-free.dev/api';

  static const String login = '/Auth/login';
  static const String firebaseLogin = '/FirebaseAuth/login';
  static const String register = '/Auth/register';
  static const String sendOtp = '/Auth/send-otp';
  static const String verifyOtp = '/Auth/verify-otp';
  static const String checkPhone = '/Auth/check-phone';
  static const String users = '/users';
  static const String updateProfile = '/users/profile';
}
