class ApiEndpoints {
  /// BE deploy (nginx) — HTTP. Emulator local: `http://10.0.2.2:<port>/api`; máy thật: IP LAN hoặc URL này.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://finlike-lorrie-refreshfully.ngrok-free.dev/api',
  );

  static const String login = '/Auth/login';
  static const String firebaseLogin = '/FirebaseAuth/login';
  static const String register = '/Auth/register';
  static const String sendOtp = '/Auth/send-otp';
  static const String verifyOtp = '/Auth/verify-otp';
  static const String checkPhone = '/Auth/check-phone';
  static const String users = '/users';
  static const String userMe = '/users/me';
  static const String updateProfile = '/users/me';

  static const String membershipPlans = '/customer-memberships/plans';
  static const String currentMembership = '/customer-memberships/me';
  static const String subscribeMembership = '/customer-memberships/subscribe';
  static const String cancelMembershipRenewal = '/customer-memberships/me/cancel-renewal';
  static const String resetMembershipTest = '/customer-memberships/me/dev-reset';
  static const String paymentIntents = '/payments/intents';
  static const String payments = '/payments';
  static const String mechanicDocuments = '/mechanics/me/documents';
  static const String mechanicDashboard = '/mechanics/me/dashboard';
  static const String mechanicCustomerHistory = '/mechanics/me/history';
  static const String mechanicWallet = '/mechanics/me/wallet';
  static const String mechanicSubscription = '/mechanics/me/subscription';
  static const String mechanicWalletDeposit = '/mechanics/me/wallet/deposit';
  static const String mechanicWalletWithdraw = '/mechanics/me/wallet/withdraw';
  static const String mechanicRepairServices = '/mechanics/me/repair/services';
  static const String mechanicSpareParts = '/mechanics/me/spare-parts';
  static const String mechanicActiveOrder = '/mechanics/me/orders/active';
  static const String mechanicDevSimulateAccept = '/mechanics/me/orders/dev-simulate-accept';
  static String mechanicOrderQuote(String orderId) => '/mechanics/me/orders/$orderId/quote';
  static String mechanicOrderArrive(String orderId) => '/mechanics/me/orders/$orderId/arrive';
  static String mechanicOrderStartRepair(String orderId) => '/mechanics/me/orders/$orderId/start-repair';
  static String mechanicCompleteRepair(String orderId) => '/mechanics/me/orders/$orderId/complete-repair';
}
