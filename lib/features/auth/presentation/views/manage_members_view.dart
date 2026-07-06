//manage members view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageMembersView extends StatelessWidget {
  const ManageMembersView({super.key});

  // মেম্বার ডিলিট করার ফাংশন
  Future<void> _deleteUser(
    BuildContext context,
    String docId,
    String userName,
  ) async {
    // ডিলিট করার আগে কনফার্মেশন ডায়ালগ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Delete ⚠️',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'আপনি কি নিশ্চিতভাবেই $userName-এর অ্যাকাউন্ট ডিলিট করতে চান? এই অ্যাকশনটি রিভার্স করা যাবে না।',
          style: const TextStyle(color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // ১. মূল ইউজার প্রোফাইল ডিলিট
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .delete();

        // ২. সেফটি হিসেবে তার ডায়েট ও ওয়ার্কআউট চার্টও ডিলিট করে দেওয়া
        await FirebaseFirestore.instance
            .collection('diet_charts')
            .doc(docId)
            .delete();
        await FirebaseFirestore.instance
            .collection('workout_charts')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('মেম্বার সফলভাবে ডিলিট করা হয়েছে! 🗑️'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ডিলিট করতে সমস্যা হয়েছে: $e'),
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
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
              // টপ মেম্বার কাউন্টারカード
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL ACTIVE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registered Members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$totalUsers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
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

                    // প্রোফাইল ইনফো
                    final height = data['height'] ?? 'N/A';
                    final weight = data['weight'] ?? 'N/A';
                    final bloodGroup = data['bloodGroup'] ?? 'N/A';
                    final emergencyContact = data['emergencyContact'] ?? 'N/A';

                    // ⏰ প্ল্যান ও বাকি দিন হিসাবের মূল লজিক (Admin Area)
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
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ExpansionTile(
                        backgroundColor: const Color(0xFF1A1D29),
                        collapsedBackgroundColor: const Color(0xFF1A1D29),
                        shape: const Border(),
                        iconColor: Colors.blueAccent,
                        collapsedIconColor: Colors.grey,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                                // ইনফো গ্রিড রো
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

                                // 💳 নতুন যুক্ত করা সেকশন: মেম্বারশিপ প্ল্যান এবং বাকি দিন (Days Left) 🎯
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
                                  child: Row(
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
                                // ডিলিট বাটন
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _deleteUser(context, docId, name),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Delete Member Account',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.redAccent,
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
    return Column(
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
        ),
      ],
    );
  }
}
