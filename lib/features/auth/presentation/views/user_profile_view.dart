import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // 👈 তারিখ ফরম্যাটিংয়ের জন্য যোগ করা হয়েছে
import '../controllers/auth_controller.dart';
import 'user_contact_trainer_view.dart';

class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  // প্রোফাইল এডিট করার জন্য বটম শিট ফর্ম (Age, Gender, Goal সহ)
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
    final ageController = TextEditingController(text: userData['age'] ?? '');

    // ড্রপডাউন ভ্যালু ম্যানেজমেন্ট (ডিফল্ট 'Male')
    String selectedGender =
        userData['gender'] == '--' || userData['gender'] == null
        ? 'Male'
        : userData['gender'];
    String selectedGoal =
        userData['goal'] == 'Not set' || userData['goal'] == null
        ? 'Weight Loss'
        : userData['goal'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            ageController,
                            'Age',
                            Icons.cake_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            bloodController,
                            'Blood Group',
                            Icons.bloodtype_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Gender ড্রপডাউন
                    _buildDropdownField(
                      label: 'Gender',
                      value: selectedGender,
                      items: ['Male', 'Female', 'Other'],
                      icon: Icons.wc_rounded,
                      onChanged: (val) => setState(() => selectedGender = val!),
                    ),
                    const SizedBox(height: 12),

                    // Fitness Goal ড্রপডাউন
                    _buildDropdownField(
                      label: 'Fitness Goal',
                      value: selectedGoal,
                      items: [
                        'Weight Loss',
                        'Muscle Gain',
                        'Stay Fit',
                        'Endurance',
                      ],
                      icon: Icons.track_changes_rounded,
                      onChanged: (val) => setState(() => selectedGoal = val!),
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
                                  'age': ageController.text.trim(),
                                  'gender': selectedGender,
                                  'goal': selectedGoal,
                                }, SetOptions(merge: true));

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile updated successfully! 🔥',
                                  ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
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

          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            userData = snapshot.data!.data() as Map<String, dynamic>;
          }

          String userName = userData['name'] ?? 'Gym Member';
          String height = userData['height'] ?? '--';
          String weight = userData['weight'] ?? '--';
          String blood = userData['blood'] ?? '--';
          String phone = userData['phone'] ?? 'Not added';
          String age = userData['age'] ?? '--';
          String gender = userData['gender'] ?? '--';
          String goal = userData['goal'] ?? 'Not set';

          // 🆔 dynamic Gym ID
          String gymId = userData['gymId'] ?? 'N/A';

          // 📅 dynamic Join Date
          String joinDateText = 'N/A';
          if (userData['joiningDate'] != null) {
            final Timestamp joinTimestamp = userData['joiningDate'];
            final DateTime joinDate = joinTimestamp.toDate();
            joinDateText = DateFormat('dd MMM yyyy').format(joinDate);
          }

          // জেন্ডার অনুযায়ী আইকন এবং থিম কালার কন্ডিশন
          IconData avatarIcon = Icons.person_rounded;
          Color genderColor = Colors.blueAccent;

          if (gender == 'Male') {
            avatarIcon = Icons.male_rounded;
            genderColor = Colors.blueAccent;
          } else if (gender == 'Female') {
            avatarIcon = Icons.female_rounded;
            genderColor = Colors.pinkAccent; // ফিমেল হলে পিঙ্ক থিম অ্যাভাটার
          } else if (gender == 'Other') {
            avatarIcon = Icons.wc_rounded;
            genderColor = Colors.purpleAccent;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ১. প্রোফাইল পিকচার (জেন্ডার ভিত্তিক অ্যাভাটার) ও নাম সেকশন
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: genderColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: genderColor.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: const Color(0xFF1A1D29),
                              child: Icon(
                                avatarIcon, // ডাইনামিক জেন্ডার আইকন
                                size: 70,
                                color: genderColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: genderColor,
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
                        icon: Icon(Icons.edit, size: 16, color: genderColor),
                        label: Text(
                          'Edit Profile Info',
                          style: TextStyle(color: genderColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ২. ফিজিক্যাল ইনফরমেশন গ্রিড (Age সহ)
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
                          const SizedBox(width: 10),
                          _buildInfoCard(
                            'Weight',
                            weight,
                            Icons.monitor_weight_rounded,
                            Colors.cyanAccent,
                          ),
                          const SizedBox(width: 10),
                          _buildInfoCard(
                            'Age',
                            age,
                            Icons.cake_rounded,
                            Colors.orangeAccent,
                          ),
                          const SizedBox(width: 10),
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
                const SizedBox(height: 24),

                // ৩. অতিরিক্ত মেম্বারশিপ, জেন্ডার ও গোল অ্যাকাউন্ট ইনফো লিস্ট
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
                          'Gender',
                          gender,
                          Icons.wc_rounded,
                          iconColor: genderColor,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildListTile(
                          'Fitness Goal',
                          goal,
                          Icons.track_changes_rounded,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildListTile(
                          'Gym Membership ID',
                          gymId, // 👈 ডাইনামিক Gym ID
                          Icons.badge_rounded,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildListTile(
                          'Join Date',
                          joinDateText, // 👈 ডাইনামিক Join Date
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

                const SizedBox(height: 24),

                // ৪. এক্সপার্ট ট্রেইনার বাটন সেকশন
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D29),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const UserContactTrainerView(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: Colors.blueAccent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Our Expert Trainers',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Click to view profiles and contact details',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ৫. মডার্ন লগআউট বাটন
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
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // টেক্সট ফিল্ড উইটিলিটি
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

  // ড্রপডাউন ফিল্ড ইউটিলিটি (Gender এবং Goal এর জন্য)
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A1D29),
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

  // ইনফো কার্ড ইউটিলিটি
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // লিস্ট টাইল ইউটিলিটি
  Widget _buildListTile(
    String title,
    String trailingText,
    IconData icon, {
    Color iconColor = Colors.blueAccent,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
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
