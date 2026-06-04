import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['API_BASE_URL'] ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://finlike-lorrie-refreshfully.ngrok-free.dev/api',
        );
      }
    } catch (_) {}
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://finlike-lorrie-refreshfully.ngrok-free.dev/api',
    );
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
