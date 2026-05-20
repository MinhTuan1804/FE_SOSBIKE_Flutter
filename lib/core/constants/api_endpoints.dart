class ApiEndpoints {
  /// BE deploy (nginx) — HTTP. Emulator local: `http://10.0.2.2:<port>/api`; máy thật: IP LAN hoặc URL này.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.2.105:5200/api',
  );

  static const String login = '/Auth/login';
  static const String firebaseLogin = '/FirebaseAuth/login';
  static const String register = '/Auth/register';
  static const String sendOtp = '/Auth/send-otp';
  static const String verifyOtp = '/Auth/verify-otp';
  static const String users = '/users';
  static const String membershipPlans = '/customer-memberships/plans';
  static const String currentMembership = '/customer-memberships/me';
  static const String subscribeMembership = '/customer-memberships/subscribe';
  static const String cancelMembershipRenewal = '/customer-memberships/me/cancel-renewal';
  static const String resetMembershipTest = '/customer-memberships/me/dev-reset';
  static const String paymentIntents = '/payments/intents';
  static const String payments = '/payments';
}
