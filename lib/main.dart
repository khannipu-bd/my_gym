import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/views/admin_dashboard_view.dart';
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/user_home_view.dart';

void main() async {
  // ফ্লাটার বাইন্ডিং ইনিশিয়ালাইজ করা
  WidgetsFlutterBinding.ensureInitialized();

  // সরাসরি অ্যান্ড্রয়েডের google-services.json ফাইলটি রিড করার জন্য ইনিশিয়ালাইজেশন
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clean Gym App',
      // অ্যাপের গ্লোবাল থিম ডার্ক রাখলে এরর স্ক্রিন আসলেও ব্যাকগ্রাউন্ড ডার্ক থাকবে
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF12141C),
      ),
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginView();

          // আপনার প্রোজেক্টের রোল চেকিং (ইমেইল বা রোল ভিত্তিক)
          if (user.role == 'admin' || user.email == 'admin@gym.com') {
            return const AdminDashboardView();
          } else {
            return const UserHomeView();
          }
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        ),
        // 🎯 সেফটি নেট: কোনো কারণে গ্লোবাল স্টেট এরর মোডে গেলেও অ্যাপ যাতে সাদা স্ক্রিন না হয়ে লগইন পেজেই থাকে!
        error: (err, stack) {
          debugPrint("Global Auth Error: $err"); // কনসোলে এরর প্রিন্ট হবে
          return const LoginView(); // 👈 সাদা টেক্সট স্ক্রিন উধাও! সরাসরি লগইন পেজেই আটকে রাখবে।
        },
      ),
    );
  }
}
