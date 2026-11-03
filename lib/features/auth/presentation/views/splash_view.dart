import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_view.dart';
import 'login_view.dart';
import 'pending_approval_view.dart';
import 'user_home_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  String _statusMessage = "Checking connection & services...";
  double _progressValue = 0.1;

  @override
  void initState() {
    super.initState();

    // Pulse & Glow animation for Gym Logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialization logic post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // Step 1: Connection & Services
    if (mounted) {
      setState(() {
        _statusMessage = "Checking connection & services...";
        _progressValue = 0.25;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 2: Authenticating profile
    if (mounted) {
      setState(() {
        _statusMessage = "Authenticating profile...";
        _progressValue = 0.60;
      });
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Syncing dashboard
    if (mounted) {
      setState(() {
        _statusMessage = "Syncing dashboard...";
        _progressValue = 0.90;
      });
    }

    // Ensure minimum 1.8 seconds elapsed for smooth brand experience
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 1800);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (mounted) {
      setState(() {
        _progressValue = 1.0;
      });
    }

    if (!mounted) return;

    // Check auth & Firestore profile
    if (currentUser == null) {
      _navigateTo(const LoginView());
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists || userDoc.data() == null) {
        // Document does not exist fallback cleanly to LoginView
        _navigateTo(const LoginView());
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role']?.toString().toLowerCase() ?? 'member';
      final status = userData['status']?.toString().toLowerCase() ?? 'approved';

      if (role == 'admin' || currentUser.email == 'admin@gym.com') {
        _navigateTo(const AdminDashboardView());
      } else if (role == 'member' || role == 'user') {
        if (status == 'approved') {
          _navigateTo(const UserHomeView());
        } else if (status == 'pending') {
          _navigateTo(const PendingApprovalView());
        } else {
          // If rejected or pending or other status
          _navigateTo(const PendingApprovalView());
        }
      } else {
        _navigateTo(const LoginView());
      }
    } catch (e) {
      debugPrint("Splash init Firestore error: $e");
      if (mounted) {
        _navigateTo(const LoginView());
      }
    }
  }

  void _navigateTo(Widget targetScreen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Dumbbell / Gym Logo with subtle pulsing animation
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D29),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: _glowAnimation.value,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(
                                    alpha: _glowAnimation.value * 0.7,
                                  ),
                                  blurRadius: 45,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              size: 52,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Title with cyan/blue accent
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'SPARTAN GYM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Slogan
                    Text(
                      'Power, Strength & Discipline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 56),

                    // Loading Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 56.0),
                      child: Column(
                        children: [
                          // Custom gradient progress indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 4,
                              child: LinearProgressIndicator(
                                value: _progressValue,
                                backgroundColor: const Color(0xFF1A1D29),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.cyanAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Status Message Text
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _statusMessage,
                              key: ValueKey<String>(_statusMessage),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Version Footer at Bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Powered by Softrova • v1.0.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
