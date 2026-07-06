import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDietView extends StatelessWidget {
  const UserDietView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF12141C), // নেভি ব্ল্যাক ব্যাকগ্রাউন্ড
      appBar: AppBar(
        title: const Text(
          'Diet & Nutrition 🥗',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('diet_charts')
            .doc(currentUserEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 64,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'আপনার জন্য এখনও কোনো ডায়েট চার্ট তৈরি করা হয়নি। অনুগ্রহ করে কোচের সাথে যোগাযোগ করুন। 🏋️‍♂️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // টপ মোটিভেশনাল টেক্সট
              const Text(
                'YOUR DAILY MEAL PLAN',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fuel Your Body, Smash Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ১. ব্রেকফাস্ট কার্ড (গোল্ডেন/অ্যাম্বার ভাইব)
              _buildDietCard(
                mealTitle: 'Breakfast',
                banglaTitle: 'সকালের খাবার',
                timeRange: '07:30 AM - 08:30 AM',
                description: data['breakfast'] ?? 'Not specified',
                icon: Icons.wb_twilight_rounded,
                startColor: const Color(0xFFFFB74D),
                endColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 16),

              // ২. লাঞ্চ কার্ড (অরেঞ্জ/ফিটনেস ভাইব)
              _buildDietCard(
                mealTitle: 'Lunch',
                banglaTitle: 'দুপুরের খাবার',
                timeRange: '01:30 PM - 02:30 PM',
                description: data['lunch'] ?? 'Not specified',
                icon: Icons.wb_sunny_rounded,
                startColor: const Color(0xFFFF7043),
                endColor: const Color(0xFFF4511E),
              ),
              const SizedBox(height: 16),

              // ৩. ডিনার কার্ড (রয়্যাল পার্পল/নাইট ভাইব)
              _buildDietCard(
                mealTitle: 'Dinner',
                banglaTitle: 'রাতের খাবার',
                timeRange: '08:30 PM - 09:30 PM',
                description: data['dinner'] ?? 'Not specified',
                icon: Icons.nightlight_round_sharp,
                startColor: const Color(0xFF7E57C2),
                endColor: const Color(0xFF5E35B1),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDietCard({
    required String mealTitle,
    required String banglaTitle,
    required String timeRange,
    required String description,
    required IconData icon,
    required Color startColor,
    required Color endColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29), // লাক্সারি ডার্ক কার্ড ব্যাকগ্রাউন্ড
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // কার্ডের ওপরের গ্রেডিয়েন্ট হেডার অংশ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      banglaTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // টাইমিং ব্যাজ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeRange,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // কার্ডের নিচের ডায়েট ডেসক্রিপশন অংশ
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 16,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Menu Details:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFFE2E8F0), // প্রিমিয়াম রিডেবল টেক্সট কালার
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
