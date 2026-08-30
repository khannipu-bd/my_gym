import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 👈 তারিখ ফরম্যাট সুন্দর করার জন্য

class ManageMembersView extends StatelessWidget {
  const ManageMembersView({super.key});

  // মেম্বার লক/আনব্লক (Block/Unblock) করার ফাংশন
  Future<void> _toggleBlockUser(
    BuildContext context,
    String docId,
    String userName,
    bool currentStatus,
  ) async {
    final actionText = currentStatus ? 'Unblock' : 'Block';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm $actionText ⚠️',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'আপনি কি নিশ্চিতভাবেই $userName-এর অ্যাকাউন্টটি $actionText করতে চান?',
          style: const TextStyle(color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.green : Colors.redAccent,
            ),
            child: Text(
              actionText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'isBlocked': !currentStatus,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$userName-কে সফলভাবে ${currentStatus ? 'আনব্লক' : 'ব্লক'} করা হয়েছে! 🔒',
              ),
              backgroundColor: currentStatus ? Colors.green : Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('অ্যাকশনটি সম্পন্ন করা যায়নি: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Gym Members List',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isNotEqualTo: 'admin')
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

          final docs = snapshot.data?.docs ?? [];
          final totalUsers = docs.length;
          const maxLimit = 100;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো মেম্বার খুঁজে পাওয়া যায়নি! 👤',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 আপডেটেড টপ মেম্বার কাউন্টার ও লিমিট ইন্ডিকেটর কার্ড
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL MEMBERS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Registered Slots',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$totalUsers',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              ' / $maxLimit',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalUsers / maxLimit,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.greenAccent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'MEMBERS DETAILS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // মেম্বার লিস্ট
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: totalUsers,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final name = data['name'] ?? 'Unknown User';
                    final email = data['email'] ?? docId;

                    // 🆔 Gym ID & 📅 Join Date ডাটাবেজ থেকে নিয়ে আসা
                    final gymId = data['gymId'] ?? 'N/A';
                    String joinDateText = 'N/A';

                    if (data['joiningDate'] != null) {
                      final Timestamp joinTimestamp = data['joiningDate'];
                      final DateTime joinDate = joinTimestamp.toDate();
                      joinDateText = DateFormat('dd MMM yyyy').format(joinDate);
                    }

                    // প্রোফাইল ইনফো
                    final height = data['height'] ?? 'N/A';
                    final weight = data['weight'] ?? 'N/A';
                    final bloodGroup = data['blood'] ?? 'N/A';
                    final emergencyContact = data['phone'] ?? 'N/A';

                    final age = data['age'] ?? 'N/A';
                    final gender = data['gender'] ?? 'N/A';
                    final goal = data['goal'] ?? 'N/A';

                    final bool isBlocked = data['isBlocked'] ?? false;

                    // ⏰ প্ল্যান ও বাকি দিন হিসাব
                    final String planName = data['planName'] ?? 'No Plan';
                    bool isActive = data['isSubscribed'] ?? false;
                    String daysLeftText = "Expired";

                    if (data['expiryDate'] != null) {
                      final Timestamp expiryTimestamp = data['expiryDate'];
                      final DateTime expiryDate = expiryTimestamp.toDate();
                      final DateTime today = DateTime.now();

                      final difference =
                          DateTime(
                                expiryDate.year,
                                expiryDate.month,
                                expiryDate.day,
                              )
                              .difference(
                                DateTime(today.year, today.month, today.day),
                              )
                              .inDays;

                      if (difference > 0 && isActive) {
                        daysLeftText = "$difference Days Remaining";
                      } else if (difference == 0 && isActive) {
                        daysLeftText = "Expires Today! ⚠️";
                      } else {
                        daysLeftText = "Expired / Inactive";
                        isActive = false;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D29),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBlocked
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ExpansionTile(
                        backgroundColor: const Color(0xFF1A1D29),
                        collapsedBackgroundColor: const Color(0xFF1A1D29),
                        shape: const Border(),
                        iconColor: Colors.blueAccent,
                        collapsedIconColor: Colors.grey,
                        leading: CircleAvatar(
                          backgroundColor: isBlocked
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.blueAccent.withOpacity(0.1),
                          child: Icon(
                            isBlocked
                                ? Icons.lock_rounded
                                : Icons.person_rounded,
                            color: isBlocked
                                ? Colors.redAccent
                                : Colors.blueAccent,
                          ),
                        ),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // 🆔 Gym ID ব্যাজ
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                gymId,
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isBlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LOCKED',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Divider(color: Colors.white10, height: 1),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoTag('Age', age),
                                    _buildInfoTag('Gender', gender),
                                    _buildInfoTag('Goal', goal),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoTag('Height', height),
                                    _buildInfoTag('Weight', weight),
                                    _buildInfoTag('Blood', bloodGroup),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 💳 মেম্বারশিপ প্ল্যান, বাকি দিন এবং 📅 Join Date
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.greenAccent.withOpacity(0.2)
                                          : Colors.redAccent.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isActive
                                                ? Icons.lock_clock_outlined
                                                : Icons.timer_off_outlined,
                                            color: isActive
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Plan: $planName',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  daysLeftText,
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? Colors.greenAccent
                                                        : Colors.redAccent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        color: Colors.white10,
                                        height: 16,
                                      ),
                                      // 📅 Join Date রো
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            color: Colors.blueAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Joined: $joinDateText',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ইমার্জেন্সি কন্টাক্ট রো
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.emergency_share_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Emergency Contact: $emergencyContact',
                                        style: const TextStyle(
                                          color: Color(0xFFE2E8F0),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 🔒 লক/আনব্লক বাটন
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _toggleBlockUser(
                                      context,
                                      docId,
                                      name,
                                      isBlocked,
                                    ),
                                    icon: Icon(
                                      isBlocked
                                          ? Icons.lock_open_rounded
                                          : Icons.lock_person_rounded,
                                      color: isBlocked
                                          ? Colors.green
                                          : Colors.redAccent,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isBlocked
                                          ? 'Unblock Member Account'
                                          : 'Block Member Account',
                                      style: TextStyle(
                                        color: isBlocked
                                            ? Colors.green
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isBlocked
                                            ? Colors.green
                                            : Colors.redAccent,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTag(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
