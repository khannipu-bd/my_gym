import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'admin_dashboard_view.dart';
import 'user_home_view.dart';
import 'login_view.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _checkAuthStatus();
    });
  }

  void _checkAuthStatus() {
    // কন্ট্রোলার থেকে কারেন্ট ইউজারের ডেটা রিড করা হচ্ছে
    final authState = ref.read(authControllerProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          if (user.email == 'admin@gym.com') {
            // অ্যাডমিন ইমেইল চেক
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardView(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHomeView()),
            );
          }
        } else {
          _goToLogin();
        }
      },
      error: (_, __) =>
          _goToLogin(), // এরর আসলেও সেফটি হিসেবে লগইন স্ক্রিনে পাঠাবে
      loading: () => _goToLogin(),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D29),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 70,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'X-FITNESS GYM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Shape Your Ultimate Self',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
