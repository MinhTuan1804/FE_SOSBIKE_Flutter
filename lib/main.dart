import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_navigator.dart';
import 'core/navigation/auth_gate.dart';
import 'core/network/dio_client.dart';
import 'core/services/auth_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/theme/app_colors.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/presentation/providers/home_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // App vẫn tiếp tục chạy UI để không bị màn hình trắng, 
    // nhưng các chức năng Firebase sẽ lỗi cho đến khi cấu hình đúng google-services.json
  }
  
  // 1. Khởi tạo Services dùng chung
  final authService = AuthService();
  final dioClient = DioClient(authService);
  
  // 2. Khởi tạo Repositories
  final authRepository = AuthRepository(dioClient);
  final homeRepository = HomeRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository, authService),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(homeRepository),
        ),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
