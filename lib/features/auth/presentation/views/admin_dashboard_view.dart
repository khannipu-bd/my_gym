// Admin Dashboard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'add_notice_view.dart';
import 'add_member_view.dart';
import 'user_home_view.dart';
import 'add_diet_view.dart';
import 'add_workout_view.dart';
import 'manage_members_view.dart'; // 👈 মেম্বার ম্যানেজমেন্ট ভিউ
import 'admin_trainer_management_view.dart'; // 👈 নতুন ট্রেইনার ম্যানেজমেন্ট ফাইলটি ইম্পোর্ট করা হলো

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF12141C,
      ), // থিমের সাথে মিলিয়ে ডার্ক ব্যাকগ্রাউন্ড
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ১. ইউজার অ্যাপ বা মেম্বার স্ক্রিন কেমন দেখায় তা টেস্ট করার বাটন
          /*TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeView()),
              );
            },
            icon: const Icon(Icons.remove_red_eye, color: Colors.blueAccent),
            label: const Text(
              'User View',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),*/
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin! 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control and update your gym features from here.',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),

            // ফিচার গ্রিড
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const BouncingScrollPhysics(),
                children: [
                  // ১. ওয়ার্কআউট প্ল্যান আপডেট (🏋️‍♂️)
                  _buildDashboardCard(
                    context: context,
                    title: 'Workout Plans',
                    icon: Icons.fitness_center_rounded,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWorkoutView(),
                        ),
                      );
                    },
                  ),

                  // ২. ডায়েট চার্ট আপডেট (🥗)
                  _buildDashboardCard(
                    context: context,
                    title: 'Diet Charts',
                    icon: Icons.restaurant_menu_rounded,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddDietView(),
                        ),
                      );
                    },
                  ),

                  // ৩. পুশ নোটিশ / অ্যানাউন্समেন্ট (📢)
                  _buildDashboardCard(
                    context: context,
                    title: 'Push Notices',
                    icon: Icons.campaign_rounded,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddNoticeView(),
                        ),
                      );
                    },
                  ),

                  // ৪. জিম মেম্বারদের লিস্ট ও প্রোফাইল দেখা (👤🔍)
                  _buildDashboardCard(
                    context: context,
                    title: 'Gym Members',
                    icon: Icons.group_rounded,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageMembersView(),
                        ),
                      );
                    },
                  ),

                  // ৫. মেম্বার ম্যানুয়াল রেজিস্ট্রেশন (➕)
                  _buildDashboardCard(
                    context: context,
                    title: 'Add New Member',
                    icon: Icons.person_add_alt_1_rounded,
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMemberView(),
                        ),
                      );
                    },
                  ),

                  // 🏋️‍♂️ ৬. নতুন ট্রেইনার ম্যানেজমেন্ট কার্ড (Manage Trainers)
                  _buildDashboardCard(
                    context: context,
                    title: 'Manage Trainers',
                    icon: Icons.psychology_alt_rounded,
                    color: Colors.deepOrangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminTrainerManagementView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
