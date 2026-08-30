// login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import 'admin_dashboard_view.dart';
import 'user_home_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🎯 রিফ্রেশ ইস্যু এবং পপআপ ব্লক এড়ানোর জন্য লোকাল লোডিং ভেরিয়েবল
  bool _isLocalLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // প্রিমিয়াম ডার্ক থিম কাস্টম এরর ডায়ালগ ফাংশন
  void _showErrorDialog(BuildContext context, String errorMessage) {
    String cleanMessage = errorMessage;
    String titleText = 'Login Failed';
    IconData dialogIcon = Icons.gpp_bad_rounded;
    Color iconColor = Colors.redAccent;

    // ফায়ারবেসের কমন এরর মেসেজ এবং কাস্টম স্টেট ক্লিন করা
    if (errorMessage.contains('user-not-found') ||
        errorMessage.contains('invalid-credential') ||
        errorMessage.contains('wrong-password') ||
        errorMessage.contains('invalid-email-or-password')) {
      cleanMessage =
          'Your Email or Password is wrong ! ❌\nঅনুগ্রহ করে সঠিক তথ্য দিয়ে আবার চেষ্টা করুন।';
    } else if (errorMessage == 'account-blocked') {
      titleText = 'Account Locked 🔒';
      cleanMessage =
          'দুঃখিত, এডমিন প্যানেল থেকে আপনার অ্যাকাউন্টটি সাময়িকভাবে ব্লক করা হয়েছে। অনুগ্রহ করে জিম কর্তৃপক্ষের সাথে যোগাযোগ করুন।';
    } else if (errorMessage == 'plan-expired') {
      titleText = 'Plan Expired ⏰';
      dialogIcon = Icons.timer_off_rounded;
      iconColor = Colors.orangeAccent;
      cleanMessage =
          'আপনার মেম্বারশিপ প্ল্যানের মেয়াদ শেষ হয়ে গেছে! জিম অ্যাক্সেস করতে অনুগ্রহ করে আপনার প্ল্যানটি রিনিউ করুন।';
    } else if (errorMessage.contains('network-request-failed')) {
      cleanMessage = 'ইন্টারনেট কানেকশনটি চেক করুন! 🌐';
    } else if (errorMessage.contains('invalid-email')) {
      cleanMessage = 'ইমেইল এড্রেসের ফরম্যাটটি সঠিক নয়! 📧';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1D29), // ডার্ক থিম ম্যাচিং
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // কাস্টমাইজড আইকন কন্টেইনার
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(dialogIcon, color: iconColor, size: 44),
                ),
                const SizedBox(height: 20),

                // টাইটেল
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // এরর ডেসক্রিপশন
                Text(
                  cleanMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE2E8F0),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ট্রাই এগেইন বাটন
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Okay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1D29),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 50,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Spartan GYM🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ইমেইল ইনপুট
              _buildInputField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // পাসওয়ার্ড ইনপুট
              _buildInputField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // লগইন বাটন / লোডিং স্টেট
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isLocalLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            _showErrorDialog(
                              context,
                              'অনুগ্রহ করে ইমেইল এবং পাসওয়ার্ড দুটিই পূরণ করুন।',
                            );
                            return;
                          }

                          // 🌀 লোকাল লোডিং স্পিনার চালু
                          setState(() {
                            _isLocalLoading = true;
                          });

                          // 🚀 ১. কন্ট্রোলার থেকে অথেন্টিকেশন এবং সিকিউরিটি চেক ট্রাই করা হচ্ছে
                          final errorMsg = await ref
                              .read(authControllerProvider.notifier)
                              .login(email, password);

                          // 🛑 যদি কোনো ভুল থাকে (ভুল ক্রেডেনশিয়াল, ব্লক স্ট্যাটাস, অথবা এক্সপায়ার্ড প্ল্যান)
                          if (errorMsg != null) {
                            if (mounted) {
                              setState(() {
                                _isLocalLoading = false;
                              });
                              _showErrorDialog(context, errorMsg);
                            }
                            return;
                          }

                          // 🛑 সফলভাবে সমস্ত ভ্যালিডেশন পার হলে লোকাল লোডিং স্পিনার বন্ধ
                          if (mounted) {
                            setState(() {
                              _isLocalLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}
