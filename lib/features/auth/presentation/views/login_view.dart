import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../../core/services/notification_service.dart';
import '../controllers/auth_controller.dart';
import 'admin_dashboard_view.dart';
import 'pending_approval_view.dart';
import 'user_home_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLocalLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🎯 কাস্টম এরর ডায়ালগ ফাংশন
  void _showErrorDialog(BuildContext context, String errorMessage) {
    String cleanMessage = errorMessage;
    String titleText = 'Login Failed';
    IconData dialogIcon = Icons.gpp_bad_rounded;
    Color iconColor = const Color(0xFFFF4D4D);

    if (errorMessage == 'account-pending') {
      titleText = 'Approval Pending ⏳';
      dialogIcon = Icons.hourglass_top_rounded;
      iconColor = Colors.amberAccent;
      cleanMessage =
          'Your account is still pending approval by Spartan GYM admin. You will be able to sign in once approved.';
    } else if (errorMessage == 'account-rejected') {
      titleText = 'Request Declined ❌';
      dialogIcon = Icons.cancel_outlined;
      iconColor = const Color(0xFFFF4D4D);
      cleanMessage = 'Your membership request was declined.';
    } else if (errorMessage.contains('user-not-found') ||
        errorMessage.contains('invalid-credential') ||
        errorMessage.contains('wrong-password') ||
        errorMessage.contains('invalid-email-or-password')) {
      cleanMessage =
          'Your Email or Password is wrong ! ❌\nঅনুগ্রহ করে সঠিক তথ্য দিয়ে আবার চেষ্টা করুন।';
    } else if (errorMessage == 'account-blocked') {
      titleText = 'Account Locked 🔒';
      cleanMessage =
          'দুঃখিত, এডমিন প্যানেল থেকে আপনার অ্যাকাউন্টটি সাময়িকভাবে ব্লক করা হয়েছে। অনুগ্রহ করে জিম কর্তৃপক্ষের সাথে যোগাযোগ করুন।';
    } else if (errorMessage == 'plan-expired') {
      titleText = 'Plan Expired ⏰';
      dialogIcon = Icons.timer_off_rounded;
      iconColor = const Color(0xFFFF6B35);
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
          backgroundColor: const Color(0xFF1A1D29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: iconColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(dialogIcon, color: iconColor, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  cleanMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA5ADBD),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
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
                      elevation: 4,
                      shadowColor: iconColor.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      'Got It',
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

  // 🔑 Forgot Password Flow
  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1A1D29),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF3D82F6), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3D82F6,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF3D82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Send password reset email',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA5ADBD),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your registered email address',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA5ADBD),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF3D82F6),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF12141C),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3D82F6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFFA5ADBD)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isResetting
                                  ? null
                                  : () async {
                                      final email = resetEmailController.text
                                          .trim();
                                      if (email.isEmpty ||
                                          !email.contains('@')) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter a valid registered email address.',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(() => isResetting = true);

                                      try {
                                        await fb_auth.FirebaseAuth.instance
                                            .sendPasswordResetEmail(
                                              email: email,
                                            );

                                        if (context.mounted) {
                                          Navigator.pop(dialogContext);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Password reset link sent to your email. Please check your inbox.',
                                              ),
                                              backgroundColor: Color(
                                                0xFF3D82F6,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(
                                          () => isResetting = false,
                                        );
                                        String errStr = e.toString();
                                        if (errStr.contains('user-not-found')) {
                                          errStr =
                                              'No account found with this email address.';
                                        } else if (errStr.contains(
                                          'invalid-email',
                                        )) {
                                          errStr =
                                              'The email address is badly formatted.';
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(errStr),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D82F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isResetting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Send Reset Link',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 📝 Sign Up Sheet (Admin Approval System)
  void _showSignUpSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegistering = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1D29),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B35,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Color(0xFFFF6B35),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Spartan Gym',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Submit membership registration request',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA5ADBD),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA5ADBD),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF3D82F6),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF12141C),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3D82F6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA5ADBD),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF3D82F6),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF12141C),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3D82F6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Phone / Emergency Contact',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA5ADBD),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_android_rounded,
                          color: Color(0xFF3D82F6),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF12141C),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3D82F6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 characters)',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA5ADBD),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF3D82F6),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF12141C),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3D82F6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isRegistering
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final phone = phoneController.text.trim();
                                final password = passwordController.text.trim();

                                if (name.isEmpty ||
                                    email.isEmpty ||
                                    password.isEmpty ||
                                    phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill in all fields including Phone.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                if (password.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password must be at least 6 characters long.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => isRegistering = true);

                                final err = await ref
                                    .read(authControllerProvider.notifier)
                                    .signUp(
                                      name: name,
                                      email: email,
                                      password: password,
                                      phone: phone,
                                    );

                                if (context.mounted) {
                                  setSheetState(() => isRegistering = false);
                                  if (err == null) {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF1A1D29,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.amberAccent,
                                            width: 1,
                                          ),
                                        ),
                                        title: const Row(
                                          children: [
                                            Icon(
                                              Icons.hourglass_top_rounded,
                                              color: Colors.amberAccent,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Pending Approval',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: const Text(
                                          'Registration submitted! Your account is pending admin approval. You will be able to sign in once approved.',
                                          style: TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            height: 1.4,
                                          ),
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.amberAccent,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'Understand',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (err == 'limit-reached') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Member capacity limit reached. Please contact Admin.',
                                        ),
                                        backgroundColor: Colors.orangeAccent,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(err),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isRegistering
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SUBMIT REGISTRATION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      body: Stack(
        children: [
          // 🌌 Background Ambient Radial Glow & Geometric Lines
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPatternPainter()),
          ),
          Positioned(
            top: -100,
            left: screenWidth / 2 - 175,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3D82F6).withValues(alpha: 0.18),
                    const Color(0xFF3D82F6).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 📱 Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),

                    // 🛡️ 1. Main Highlight: Original Asset Logo with Sleek Glowing Frame
                    const _SpartanLogoWidget(),

                    const SizedBox(height: 24),

                    // 🏆 2. Brand Title & Tagline
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFDCE6FB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        'SPARTAN GYM',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 2,
                          color: const Color(0xFFFF6B35),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BUILD STRENGTH. STAY STRONG.',
                          style: TextStyle(
                            color: Color(0xFF5A9BFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 2,
                          color: const Color(0xFFFF6B35),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ✉️ 3. Welcome Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151925),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Welcome Back, Warrior!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF6B35,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '⚡',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sign in to continue your fitness journey.',
                            style: TextStyle(
                              color: Color(0xFFA5ADBD),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 📧 4. Email Field
                    _buildInputField(
                      controller: _emailController,
                      hintText: 'Enter your email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // 🔒 5. Password Field
                    _buildInputField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFA5ADBD),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ❓ Forgot Password Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF5A9BFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🚀 6. Premium CTA Button: SIGN IN
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3D82F6), Color(0xFF1D58D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3D82F6,
                            ).withValues(alpha: 0.45),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLocalLoading
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text
                                    .trim();

                                if (email.isEmpty || password.isEmpty) {
                                  _showErrorDialog(
                                    context,
                                    'অনুগ্রহ করে ইমেইল এবং পাসওয়ার্ড দুটিই পূরণ করুন।',
                                  );
                                  return;
                                }

                                setState(() {
                                  _isLocalLoading = true;
                                });

                                final errorMsg = await ref
                                    .read(authControllerProvider.notifier)
                                    .login(email, password);

                                if (!mounted) return;

                                if (errorMsg != null) {
                                  setState(() {
                                    _isLocalLoading = false;
                                  });
                                  if (context.mounted) {
                                    _showErrorDialog(context, errorMsg);
                                  }
                                  return;
                                }

                                // Immediately after successful Firebase auth sign-in
                                try {
                                  await NotificationService.initialize();
                                  await NotificationService.saveFcmToken();
                                  final currentUser =
                                      fb_auth.FirebaseAuth.instance.currentUser;

                                  if (currentUser != null) {
                                    final userDoc = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .get();

                                    if (!mounted) return;

                                    if (userDoc.exists &&
                                        userDoc.data() != null) {
                                      final userData =
                                          userDoc.data()
                                              as Map<String, dynamic>;
                                      final role =
                                          userData['role']
                                              ?.toString()
                                              .toLowerCase() ??
                                          'member';
                                      final status =
                                          userData['status']
                                              ?.toString()
                                              .toLowerCase() ??
                                          'approved';

                                      if (!context.mounted) return;

                                      if (role == 'admin' ||
                                          currentUser.email ==
                                              'admin@gym.com') {
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AdminDashboardView(),
                                          ),
                                          (route) => false,
                                        );
                                        return;
                                      } else if (role == 'member' ||
                                          role == 'user') {
                                        if (status == 'approved') {
                                          Navigator.of(
                                            context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const UserHomeView(),
                                            ),
                                            (route) => false,
                                          );
                                          return;
                                        } else if (status == 'pending') {
                                          Navigator.of(
                                            context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PendingApprovalView(),
                                            ),
                                            (route) => false,
                                          );
                                          return;
                                        } else {
                                          Navigator.of(
                                            context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PendingApprovalView(),
                                            ),
                                            (route) => false,
                                          );
                                          return;
                                        }
                                      }
                                    }
                                  }

                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UserHomeView(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() {
                                    _isLocalLoading = false;
                                  });
                                  if (context.mounted) {
                                    _showErrorDialog(
                                      context,
                                      'Login error: $e',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLocalLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 👤 7. Sign Up Link Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFFA5ADBD),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showSignUpSheet(context),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF5A9BFF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ Modern Input Field Builder
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151925),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA5ADBD), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: const Color(0xFF3D82F6), size: 22),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3D82F6), width: 1.8),
          ),
        ),
      ),
    );
  }
}

// 🛡️ Custom Spartan Gym Asset Logo Component
class _SpartanLogoWidget extends StatelessWidget {
  const _SpartanLogoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF151925),
        border: Border.all(
          color: const Color(0xFF3D82F6).withValues(alpha: 0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D82F6).withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/images/app_logo.png',
          height: 110,
          width: 110,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.fitness_center_rounded,
              size: 50,
              color: Color(0xFF3D82F6),
            );
          },
        ),
      ),
    );
  }
}

// 🌌 Custom Painter for Dark Ambient Background Mesh
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF3D82F6).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
