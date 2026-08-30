// user diet view.dart
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

          // ফায়ারস্টোর ম্যাপ অবজেক্ট থেকে সেফলি ডেটা পার্স করার লজিক
          Map<String, dynamic> getMealData(String key) {
            if (data[key] is Map) {
              return Map<String, dynamic>.from(data[key]);
            }
            return {
              'food': data[key] ?? 'Not specified',
              'note': '',
              'kcal': '--',
            };
          }

          final breakfastMap = getMealData('breakfast');
          final lunchMap = getMealData('lunch');
          final dinnerMap = getMealData('dinner');

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

              // ১. ব্রেকফাস্ট কার্ড
              _buildDietCard(
                mealTitle: 'Breakfast',
                banglaTitle: 'সকালের খাবার',
                timeRange: '07:30 - 08:30 AM',
                description: breakfastMap['food'] ?? 'Not specified',
                note: breakfastMap['note'] ?? '',
                kcal: breakfastMap['kcal'] ?? '',
                icon: Icons.wb_twilight_rounded,
                startColor: const Color(0xFFFFB74D),
                endColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 16),

              // ২. লাঞ্চ কার্ড
              _buildDietCard(
                mealTitle: 'Lunch',
                banglaTitle: 'দুপুরের খাবার',
                timeRange: '01:30 - 02:30 PM',
                description: lunchMap['food'] ?? 'Not specified',
                note: lunchMap['note'] ?? '',
                kcal: lunchMap['kcal'] ?? '',
                icon: Icons.wb_sunny_rounded,
                startColor: const Color(0xFFFF7043),
                endColor: const Color(0xFFF4511E),
              ),
              const SizedBox(height: 16),

              // ৩. ডিনার কার্ড
              _buildDietCard(
                mealTitle: 'Dinner',
                banglaTitle: 'রাতের খাবার',
                timeRange: '08:30 - 09:30 PM',
                description: dinnerMap['food'] ?? 'Not specified',
                note: dinnerMap['note'] ?? '',
                kcal: dinnerMap['kcal'] ?? '',
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
    required String note,
    required String kcal,
    required IconData icon,
    required Color startColor,
    required Color endColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
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
          // কার্ডের ওপরের গ্রেডিয়েন্ট হেডার অংশ (ওভারফ্লো ফিক্সড করা হয়েছে 🛠️)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 10),

                // মিল টাইটেলকে Expanded করা হলো যাতে এটি ডানে পুশ না করে
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        banglaTitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // ক্যালরি ব্যাজ এবং টাইমিং এরিয়া
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ক্যালরি ব্যাজ
                    if (kcal.isNotEmpty && kcal != '--')
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.orangeAccent,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$kcal kcal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // টাইমিং ব্যাজ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                  description.isEmpty ? 'Not specified' : description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // কোচের বিশেষ নোট বক্স
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amberAccent.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Colors.amberAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Coach's Instruction:",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
