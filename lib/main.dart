import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_navigator.dart';
import 'core/navigation/auth_gate.dart';
import 'core/navigation/auth_navigation.dart';
import 'core/network/dio_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/backend_otp_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/theme/app_colors.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/membership/data/repositories/membership_repository.dart';
import 'features/membership/presentation/providers/membership_provider.dart';
import 'features/profile/data/repositories/vehicle_repository.dart';
import 'features/profile/presentation/providers/vehicle_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  } else {
    debugPrint('Web: đăng nhập bằng mật khẩu / OTP qua BE local.');
  }

  // 1. Khởi tạo Services dùng chung
  final authService = AuthService();
  final dioClient = DioClient(authService);

  // 2. Khởi tạo Repositories
  final authRepository = AuthRepository(dioClient);
  final homeRepository = HomeRepository();
  final membershipRepository = MembershipRepository(dioClient);
  final vehicleRepository = VehicleRepository(dioClient);
  final backendOtpService = BackendOtpService(dioClient);

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
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => HomeProvider(homeRepository)),
        ChangeNotifierProvider(create: (_) => MembershipProvider(membershipRepository)),
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
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'SOSbike',
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
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
