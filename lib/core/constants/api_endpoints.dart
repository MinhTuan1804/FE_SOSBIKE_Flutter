import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  /// Local BE mặc định khi dev; override bằng `--dart-define` hoặc `.env`.
  static const String _localDevBaseUrl = 'https://api.sosbike.io.vn/api';

  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;

    try {
      if (dotenv.isInitialized) {
        final fromEnv = dotenv.env['API_BASE_URL']?.trim();
        if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
      }
    } catch (_) {}

    return kDebugMode ? _localDevBaseUrl : _localDevBaseUrl;
  }

  static const String login = '/Auth/login';
  static const String firebaseLogin = '/FirebaseAuth/login';
  static const String register = '/Auth/register';
  static const String sendOtp = '/Auth/send-otp';
  static const String verifyOtp = '/Auth/verify-otp';
  static const String checkPhone = '/Auth/check-phone';
  static const String users = '/users';
  static const String userMe = '/users/me';
  static const String updateProfile = '/users/me';
  static const String sendEmailVerification = '/users/me/send-email-verification';

  static const String membershipPlans = '/customer-memberships/plans';
  static const String currentMembership = '/customer-memberships/me';
  static const String subscribeMembership = '/customer-memberships/subscribe';
  static const String cancelMembershipRenewal = '/customer-memberships/me/cancel-renewal';
  static const String resetMembershipTest = '/customer-memberships/me/dev-reset';
  static const String paymentIntents = '/payments/intents';
  static const String payments = '/payments';
  static const String mechanicDocuments = '/mechanics/me/documents';
  static const String appConfig = '/config/app';
  static const String blogs = '/blogs';
  static String blogTrackView(String slug) => '/blogs/$slug/view';
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static String notificationMarkRead(int notificationId) => '/notifications/$notificationId/read';
  static const String notificationMarkAllRead = '/notifications/read-all';

  static const String chatConversations = '/chats/conversations';

  static String chatMessages(String orderId) => '/chats/orders/$orderId/messages';

  static String chatMarkRead(String orderId) => '/chats/orders/$orderId/read';

  static const String refreshToken = '/Auth/refresh-token';
  static const String mechanicDashboard = '/mechanics/me/dashboard';
  static const String mechanicCustomerHistory = '/mechanics/me/history';
  static const String mechanicWallet = '/mechanics/me/wallet';
  static const String mechanicSubscription = '/mechanics/me/subscription';
  static const String mechanicSubscriptionPlans = '/mechanics/me/subscription/plans';
  static const String mechanicSubscriptionSubscribe = '/mechanics/me/subscription/subscribe';
  static const String mechanicWalletDeposit = '/mechanics/me/wallet/deposit';
  static const String mechanicWalletWithdraw = '/mechanics/me/wallet/withdraw';
  static const String mechanicRepairServices = '/mechanics/me/repair/services';
  static const String mechanicMyServices = '/mechanics/me/services';
  static String mechanicMyService(int mechanicServiceId) => '/mechanics/me/services/$mechanicServiceId';
  static const String mechanicSpareParts = '/mechanics/me/spare-parts';
  static const String mechanicActiveOrder = '/mechanics/me/orders/active';
  static const String mechanicDevSimulateAccept = '/mechanics/me/orders/dev-simulate-accept';

  static const String customerOrderHistory = '/customers/me/history';
  static const String customerWallet = '/customers/me/wallet';
  static String mechanicOrderQuote(String orderId) => '/mechanics/me/orders/$orderId/quote';
  static String mechanicOrderArrive(String orderId) => '/mechanics/me/orders/$orderId/arrive';
  static String mechanicOrderStartRepair(String orderId) => '/mechanics/me/orders/$orderId/start-repair';
  static String mechanicCompleteRepair(String orderId) => '/mechanics/me/orders/$orderId/complete-repair';
  static String mechanicSettleCash(String orderId) => '/mechanics/me/orders/$orderId/settle-cash';
}
