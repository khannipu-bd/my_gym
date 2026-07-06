import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // প্রিমিয়াম ডার্ক থিম কাস্টম এরর ডায়ালগ ফাংশন
  void _showErrorDialog(BuildContext context, String errorMessage) {
    String cleanMessage = errorMessage;

    // ফায়ারবেসের কমন এরর মেসেজ ক্লিন করা
    if (errorMessage.contains('user-not-found') ||
        errorMessage.contains('invalid-credential') ||
        errorMessage.contains('wrong-password') ||
        errorMessage.contains('invalid-email-or-password')) {
      cleanMessage =
          'Your Email or Password is wrong ! ❌\nঅনুগ্রহ করে সঠিক তথ্য দিয়ে আবার চেষ্টা করুন।';
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
                // প্রিমিয়াম রেড এরর আইকন
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: Colors.redAccent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),

                // タイトル
                const Text(
                  'Login Failed',
                  style: TextStyle(
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
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Try Again',
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
    // 🎯 নোট: এখান থেকে গ্লোবাল ref.listen ব্লকটি পুরোপুরি বাদ দেওয়া হয়েছে,
    // কারণ নেভিগেশন এখন main.dart এবং এরর হ্যান্ডলিং সরাসরি বাটন ক্লিক দিয়ে হচ্ছে।

    final authState = ref.watch(authControllerProvider);

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
                  'Welcome Back 🔥',
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
                child: authState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      )
                    : ElevatedButton(
                        // 🎯 এখানে বাটনটি async করা হয়েছে সরাসরি রেসপন্স হ্যান্ডেল করার জন্য
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

                          // 🚀 কন্ট্রোলার থেকে সরাসরি এরর মেসেজটি রিড করা হচ্ছে
                          final errorMsg = await ref
                              .read(authControllerProvider.notifier)
                              .login(email, password);

                          // ⚠️ যদি কোনো এরর মেসেজ আসে, সাথে সাথে পপআপ ডায়ালগটি ওপেন হবে
                          if (errorMsg != null && context.mounted) {
                            _showErrorDialog(context, errorMsg);
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
