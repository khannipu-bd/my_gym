// user home view.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile_view.dart';
import 'user_diet_view.dart';
import 'user_workout_view.dart';

class UserHomeView extends ConsumerStatefulWidget {
  const UserHomeView({super.key});

  @override
  ConsumerState<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends ConsumerState<UserHomeView> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenContent(),
    const UserWorkoutView(),
    const UserDietView(),
    const UserProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1D29),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_rounded),
            label: 'Diet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final String currentUserEmail =
      FirebaseAuth.instance.currentUser?.email ??
      ""; // 👈 ইমেইল ট্র্যাকের জন্য যোগ করা হলো
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAsRead(String docId) {
    if (currentUserId.isEmpty) return;
    FirebaseFirestore.instance.collection('notices').doc(docId).update({
      'readBy': FieldValue.arrayUnion([currentUserId]),
    });
  }

  void _showNoticeDetails(String docId, String title, String content) {
    _markAsRead(docId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateBMI(String heightStr, double weight) {
    if (weight <= 0 || heightStr.isEmpty || heightStr == "0.0") {
      return {
        'bmi': 0.0,
        'status': 'No Data',
        'color': Colors.grey,
        'displayHeight': '0\'0"',
        'waterGoal': '2.5 L',
        'burnGoal': '350 kcal',
        'stepsGoal': '6,000',
      };
    }

    int feet = 0;
    int inches = 0;

    try {
      if (heightStr.contains('.')) {
        final parts = heightStr.split('.');
        feet = int.tryParse(parts[0]) ?? 0;
        inches = int.tryParse(parts[1]) ?? 0;
      } else {
        feet = int.tryParse(heightStr) ?? 0;
      }
    } catch (e) {
      print("Height parsing error: $e");
    }

    int totalInches = (feet * 12) + inches;
    double heightInMeters = totalInches * 0.0254;

    if (heightInMeters <= 0) {
      return {
        'bmi': 0.0,
        'status': 'No Data',
        'color': Colors.grey,
        'displayHeight': '0\'0"',
        'waterGoal': '2.5 L',
        'burnGoal': '350 kcal',
        'stepsGoal': '6,000',
      };
    }

    double bmi = weight / pow(heightInMeters, 2);

    String status;
    Color color;
    String waterGoal = "3.0 L";
    String burnGoal = "450 kcal";
    String stepsGoal = "8,000";

    if (bmi < 18.5) {
      status = 'Underweight 🦴 (ওজন কম)';
      color = Colors.orangeAccent;
      waterGoal = "2.5 L";
      burnGoal = "350 kcal";
      stepsGoal = "6,500";
    } else if (bmi >= 18.5 && bmi < 25.0) {
      status = 'Normal Weight ✨ (ফিট)';
      color = Colors.greenAccent;
      waterGoal = "3.0 L";
      burnGoal = "450 kcal";
      stepsGoal = "8,000";
    } else if (bmi >= 25.0 && bmi < 30.0) {
      status = 'Overweight ⚠️ (বাড়তি ওজন)';
      color = Colors.amberAccent;
      waterGoal = "3.5 L";
      burnGoal = "550 kcal";
      stepsGoal = "10,000";
    } else {
      status = 'Obese 🚨 (অতিরিক্ত মেদ)';
      color = Colors.redAccent;
      waterGoal = "4.0 L";
      burnGoal = "650 kcal";
      stepsGoal = "12,000";
    }

    return {
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'status': status,
      'color': color,
      'displayHeight': "$feet'$inches\"",
      'waterGoal': waterGoal,
      'burnGoal': burnGoal,
      'stepsGoal': stepsGoal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    if (currentUserId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF12141C),
        body: Center(
          child: Text(
            "User not logged in!",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Gym Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notices')
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final List readBy = data['readBy'] ?? [];
                  if (!readBy.contains(currentUserId)) {
                    unreadCount++;
                  }
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF12141C),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      color: Colors.purpleAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Announcements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.purpleAccent,
                labelColor: Colors.purpleAccent,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                  Tab(text: 'Read'),
                ],
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notices')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.purpleAccent,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No announcements yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    final allNotices = snapshot.data!.docs;
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNoticeList(allNotices, 'all'),
                        _buildNoticeList(allNotices, 'unread'),
                        _buildNoticeList(allNotices, 'read'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          String userName = "User";
          String planName = "No Active Plan";
          String daysLeftText = "Expired";
          bool isActive = false;
          double userWeight = 0.0;
          String rawHeight = "0.0";

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            userName = userData['name'] ?? "User";
            planName = userData['planName'] ?? "No Active Plan";
            isActive = userData['isSubscribed'] ?? false;
            userWeight =
                double.tryParse(userData['weight']?.toString() ?? '0') ?? 0.0;
            rawHeight = userData['height']?.toString() ?? "0.0";

            if (userData['expiryDate'] != null) {
              final Timestamp expiryTimestamp = userData['expiryDate'];
              final DateTime expiryDate = expiryTimestamp.toDate();
              final DateTime today = DateTime.now();

              final difference = DateTime(
                expiryDate.year,
                expiryDate.month,
                expiryDate.day,
              ).difference(DateTime(today.year, today.month, today.day)).inDays;

              if (difference > 0 && isActive) {
                daysLeftText = "$difference Days Remaining";
              } else if (difference == 0 && isActive) {
                daysLeftText = "Expires Today! ⚠️";
              } else {
                daysLeftText = "Expired / Inactive";
                isActive = false;
              }
            }
          }

          final bmiData = _calculateBMI(rawHeight, userWeight);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName! 🔥',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Time to Smash Your Goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ১. মেম্বারশিপ প্ল্যান কার্ড
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D29),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? Colors.greenAccent.withOpacity(0.3)
                          : Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.greenAccent.withOpacity(0.1)
                              : Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.verified_user_rounded
                              : Icons.gpp_bad_rounded,
                          color: isActive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ACTIVE GYM MEMBERSHIP',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              planName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              daysLeftText,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.greenAccent.withOpacity(0.8)
                                    : Colors.redAccent,
                                fontSize: 13,
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

                // ২. BMI ক্যালকুলেটর উইজেট
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D29),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.accessibility_new_rounded,
                                color: bmiData['color'],
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Your BMI Status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            userWeight > 0
                                ? "${bmiData['displayHeight']} | ${userWeight.toInt()} kg"
                                : "No Profile Data",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            bmiData['bmi'].toString(),
                            style: TextStyle(
                              color: bmiData['color'],
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              bmiData['status'],
                              style: TextStyle(
                                color: bmiData['color'],
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: userWeight > 0
                              ? (bmiData['bmi'] / 40).clamp(0.0, 1.0)
                              : 0.0,
                          backgroundColor: Colors.white10,
                          color: bmiData['color'],
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🛠️ ৩. ওয়ার্কআউট প্ল্যানের সাথে কানেক্ট করা ডায়নামিক কার্ড অংশ
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('workout_charts')
                      .doc(currentUserEmail)
                      .snapshots(),
                  builder: (context, workoutSnapshot) {
                    String routineTitle = "Rest Day 😴";
                    String routineDuration = "No active scheduled workout";

                    if (workoutSnapshot.hasData &&
                        workoutSnapshot.data!.exists) {
                      final workoutData =
                          workoutSnapshot.data!.data() as Map<String, dynamic>;
                      routineTitle =
                          workoutData['workoutTitle'] ?? "Workout Day";

                      // এক্সারসাইজ সংখ্যা কাউন্ট করার মেথড
                      int exercisesCount = 0;
                      if (workoutData['exercises'] is List) {
                        exercisesCount =
                            (workoutData['exercises'] as List).length;
                      }

                      final estTime =
                          workoutData['duration'] ?? "Estimated Time";
                      routineDuration = exercisesCount > 0
                          ? "$estTime • $exercisesCount Exercises"
                          : estTime;
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.purpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Workout',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            routineTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            routineDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ৪. একটিভ এবং ডাইনামিক ডেইলি স্ট্যাটাস সেকশন (BMI ভিত্তিক গোল)
                const Text(
                  'TODAY\'S TARGET (BASED ON BMI)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      'Burn Goal',
                      bmiData['burnGoal'],
                      Icons.local_fire_department_rounded,
                      Colors.orangeAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Water Target',
                      bmiData['waterGoal'],
                      Icons.water_drop_rounded,
                      Colors.blueAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Steps Goal',
                      bmiData['stepsGoal'],
                      Icons.directions_walk_rounded,
                      Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticeList(List<QueryDocumentSnapshot> docs, String filterType) {
    List<QueryDocumentSnapshot> filteredDocs = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List readBy = data['readBy'] ?? [];
      final bool isRead = readBy.contains(currentUserId);
      if (filterType == 'all' ||
          (filterType == 'unread' && !isRead) ||
          (filterType == 'read' && isRead)) {
        filteredDocs.add(doc);
      }
    }

    if (filteredDocs.isEmpty) {
      return Center(
        child: Text(
          'No $filterType notices found.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final docId = filteredDocs[index].id;
        final data = filteredDocs[index].data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Notice';
        final content = data['content'] ?? '';
        final List readBy = data['readBy'] ?? [];
        final bool isRead = readBy.contains(currentUserId);

        return Card(
          color: const Color(0xFF1A1D29),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isRead
                  ? Colors.transparent
                  : Colors.purpleAccent.withOpacity(0.3),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.purpleAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                content,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () => _showNoticeDetails(docId, title, content),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
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
}
