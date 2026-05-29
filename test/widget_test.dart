// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fe_moblie_flutter/core/config/app_config_provider.dart';
import 'package:fe_moblie_flutter/core/config/app_config_repository.dart';

import 'package:fe_moblie_flutter/main.dart';
import 'package:fe_moblie_flutter/core/services/auth_service.dart';
import 'package:fe_moblie_flutter/core/network/dio_client.dart';
import 'package:fe_moblie_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Provide a minimal AuthProvider so AuthGate can read it during init
    final authService = AuthService();
    final dioClient = DioClient(authService);
    final authRepository = AuthRepository(dioClient);
    final authProvider = AuthProvider(authRepository, authService);
    unawaited(authProvider.checkAuthStatus());

    final appConfigRepository = AppConfigRepository(dioClient);
    final appConfigProvider = AppConfigProvider(appConfigRepository);
    unawaited(appConfigProvider.load());

    // Build our app with providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppConfigProvider>.value(value: appConfigProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app builds and shows root MaterialApp (basic smoke test).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
