import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // রিভারপড ইম্পোর্ট করা হলো
import '../controllers/auth_controller.dart'; // অথ কন্ট্রোলার ইম্পোর্ট করুন

class UserProfileView extends ConsumerWidget {
  // StatelessWidget পরিবর্তন করে ConsumerWidget করা হলো
  const UserProfileView({super.key});

  // প্রোফাইল এডিট করার জন্য বটম শিট ফর্ম
  void _showEditProfileSheet(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    final nameController = TextEditingController(text: userData['name'] ?? '');
    final heightController = TextEditingController(
      text: userData['height'] ?? '',
    );
    final weightController = TextEditingController(
      text: userData['weight'] ?? '',
    );
    final bloodController = TextEditingController(
      text: userData['blood'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData['phone'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  nameController,
                  'Full Name',
                  Icons.person_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        heightController,
                        "Height (e.g. 5'8\")",
                        Icons.height_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        weightController,
                        'Weight (e.g. 74 kg)',
                        Icons.monitor_weight_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  bloodController,
                  'Blood Group (e.g. O+)',
                  Icons.bloodtype_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  phoneController,
                  'Emergency Contact',
                  Icons.contact_phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                              'name': nameController.text.trim(),
                              'height': heightController.text.trim(),
                              'weight': weightController.text.trim(),
                              'blood': bloodController.text.trim(),
                              'phone': phoneController.text.trim(),
                            }, SetOptions(merge: true));

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully! 🔥'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Save Changes',
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
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        filled: true,
        fillColor: const Color(0xFF12141C),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WidgetRef ref প্যারামিটার যোগ করা হলো
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading:
            false, // বটম ন্যাভ বারে থাকলে ব্যাক বাটনের প্রয়োজন নেই
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            userData = snapshot.data!.data() as Map<String, dynamic>;
          }

          String userName = userData['name'] ?? 'Gym Member';
          String height = userData['height'] ?? '--';
          String weight = userData['weight'] ?? '--';
          String blood = userData['blood'] ?? '--';
          String phone = userData['phone'] ?? 'Not added';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ১. প্রোফাইল পিকচার ও নাম সেকশন
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 55,
                              backgroundColor: Color(0xFF1A1D29),
                              child: Icon(
                                Icons.person_rounded,
                                size: 70,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blueAccent,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    _showEditProfileSheet(context, userData),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextButton.icon(
                        onPressed: () =>
                            _showEditProfileSheet(context, userData),
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.blueAccent,
                        ),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ২. ফিজিক্যাল ইনফরমেশন গ্রিড
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PHYSICAL INFO',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoCard(
                            'Height',
                            height,
                            Icons.height_rounded,
                            Colors.greenAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            'Weight',
                            weight,
                            Icons.monitor_weight_rounded,
                            Colors.cyanAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            'Blood',
                            blood,
                            Icons.bloodtype_rounded,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ৩. অতিরিক্ত মেম্বারশিপ অ্যাকাউন্ট ইনফো লিস্ট
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D29),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          'Gym Membership ID',
                          'GYM-2026-894',
                          Icons.badge_rounded,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildListTile(
                          'Join Date',
                          '01 July 2026',
                          Icons.calendar_today_rounded,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildListTile(
                          'Emergency Contact',
                          phone,
                          Icons.contact_phone_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 🔴 ৪. লাল রঙের মডার্ন লগআউট বাটন (নতুন যুক্ত করা হয়েছে)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Log Out Account',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ), // স্ক্রিনের নিচের দিকে একটু এক্সট্রা স্পেস
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String trailingText, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Text(
        trailingText,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
