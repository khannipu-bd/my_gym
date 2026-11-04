import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/views/splash_view.dart';

void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      // Ensure Flutter engine bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Handle Flutter framework errors gracefully without thread blocking
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Uncaught Flutter Error: ${details.exception}');
      };

      // Safe Firebase initialization
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase init error: $e');
      }

      runApp(const ProviderScope(child: MyApp()));
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught Async Zone Error: $error');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spartan Gym',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF12141C),
        canvasColor: const Color(0xFF12141C),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A1D29)),
      ),
      home: const SplashView(),
    );
  }
}
