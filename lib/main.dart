import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/constants/api_endpoints.dart';
import 'package:fe_moblie_flutter/core/config/app_config_provider.dart';
import 'package:fe_moblie_flutter/core/config/app_config_repository.dart';
import 'package:fe_moblie_flutter/core/navigation/app_navigator.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_gate.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/core/services/backend_otp_service.dart';
import 'package:fe_moblie_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/membership/data/repositories/membership_repository.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';
import 'package:fe_moblie_flutter/features/notifications/data/repositories/chat_repository.dart';
import 'package:fe_moblie_flutter/features/notifications/data/repositories/notification_repository.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/chat_realtime_service.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/notification_realtime_service.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/rescue_realtime_service.dart';
import 'package:fe_moblie_flutter/features/notifications/data/services/location_realtime_service.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/chat_provider.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/providers/notification_provider.dart';
import 'package:fe_moblie_flutter/features/home/data/repositories/rescue_repository.dart';
import 'package:fe_moblie_flutter/features/home/data/repositories/home_repository.dart';
import 'package:fe_moblie_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/repositories/customer_history_repository.dart';
import 'package:fe_moblie_flutter/features/home/customer/data/repositories/customer_wallet_repository.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/customer_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/customer_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_dashboard_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_history_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_wallet_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_subscription_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_repair_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_dashboard_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_history_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_income_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_subscription_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/repositories/mechanic_service_offering_repository.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_service_offering_provider.dart';
import 'package:fe_moblie_flutter/features/profile/data/repositories/vehicle_repository.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/providers/vehicle_provider.dart';
import 'package:fe_moblie_flutter/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }
  debugPrint('API baseUrl: ${ApiEndpoints.baseUrl}');

  if (!kIsWeb) {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        debugPrint('Firebase already initialized, skipping.');
      }
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  } else {
    debugPrint('Web: đăng nhập bằng mật khẩu / OTP qua BE local.');
  }

  // 1. Khởi tạo Services dùng chung
  final authService = AuthService();
  final dioClient = DioClient(authService);
  final appConfigRepository = AppConfigRepository(dioClient);
  final appConfigProvider = AppConfigProvider(appConfigRepository);
  unawaited(appConfigProvider.load());

  // 2. Khởi tạo Repositories
  final authRepository = AuthRepository(dioClient);
  final membershipRepository = MembershipRepository(dioClient);
  final mechanicDashboardRepository = MechanicDashboardRepository(dioClient);
  final mechanicHistoryRepository = MechanicHistoryRepository(dioClient);
  final mechanicWalletRepository = MechanicWalletRepository(dioClient);
  final mechanicSubscriptionRepository = MechanicSubscriptionRepository(dioClient);
  final mechanicRepairRepository = MechanicRepairRepository(dioClient);
  final mechanicServiceOfferingRepository = MechanicServiceOfferingRepository(dioClient);
  final vehicleRepository = VehicleRepository(dioClient);
  final backendOtpService = BackendOtpService(dioClient);
  final chatRepository = ChatRepository(dioClient);
  final chatRealtimeService = ChatRealtimeService(authService);
  final notificationRepository = NotificationRepository(dioClient);
  final notificationRealtimeService = NotificationRealtimeService(authService);
  final rescueRepository = RescueRepository(dioClient);
  final homeRepository = HomeRepository(dioClient);
  final customerHistoryRepository = CustomerHistoryRepository(dioClient);
  final customerWalletRepository = CustomerWalletRepository(dioClient);
  final rescueRealtimeService = RescueRealtimeService(authService);
  final locationRealtimeService = LocationRealtimeService(authService);

  final authProvider = AuthProvider(authRepository, authService);
  unawaited(authProvider.checkAuthStatus());
  dioClient.onUnauthorized = () async {
    if (!authProvider.isAuthenticated) return;
    await authProvider.logout();
    navigateToLogin();
  };

  if (kDebugMode) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<BackendOtpService>.value(value: backendOtpService),
        ChangeNotifierProvider<AppConfigProvider>.value(value: appConfigProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => MembershipProvider(membershipRepository)),
        ChangeNotifierProvider(create: (_) => ChatProvider(chatRepository, chatRealtimeService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationRepository, notificationRealtimeService)),
        ChangeNotifierProvider(create: (_) => RescueProvider(rescueRepository, rescueRealtimeService, locationRealtimeService)),
        ChangeNotifierProvider(create: (_) => HomeProvider(homeRepository, authService)),
        ChangeNotifierProvider(create: (_) => CustomerHistoryProvider(customerHistoryRepository)),
        ChangeNotifierProvider(create: (_) => CustomerWalletProvider(customerWalletRepository)),
        ChangeNotifierProvider(create: (_) => MechanicDashboardProvider(mechanicDashboardRepository)),
        ChangeNotifierProvider(create: (_) => MechanicHistoryProvider(mechanicHistoryRepository)),
        ChangeNotifierProvider(create: (_) => MechanicIncomeProvider(mechanicHistoryRepository)),
        ChangeNotifierProvider(create: (_) => MechanicWalletProvider(mechanicWalletRepository)),
        ChangeNotifierProvider(create: (_) => MechanicSubscriptionProvider(mechanicSubscriptionRepository)),
        ChangeNotifierProvider(create: (_) => MechanicRepairProvider(mechanicRepairRepository)),
        ChangeNotifierProvider(create: (_) => MechanicServiceOfferingProvider(mechanicServiceOfferingRepository)),
        ChangeNotifierProvider(create: (_) => VehicleProvider(vehicleRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigProvider>().config;
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: appConfig.ui.brandName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: appConfig.ui.backgroundColor,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: appConfig.ui.navbarHeaderColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
