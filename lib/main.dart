import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'core/services/auth_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Khởi tạo Services dùng chung
  final authService = AuthService();
  final dioClient = DioClient(authService);
  
  // 2. Khởi tạo Repositories
  final authRepository = AuthRepository(dioClient);
  final homeRepository = HomeRepository(dioClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository, authService)..checkAuthStatus(),
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
      title: 'Flutter C# Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Tự động điều hướng dựa trên trạng thái đăng nhập
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
