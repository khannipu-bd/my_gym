import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserWorkoutView extends StatefulWidget {
  const UserWorkoutView({super.key});

  @override
  State<UserWorkoutView> createState() => _UserWorkoutViewState();
}

class _UserWorkoutViewState extends State<UserWorkoutView> {
  // 📅 বর্তমানে মেম্বার কোন দিনটি সিলেক্ট করে দেখছেন তা ট্র্যাক করার ভ্যারিয়েবল
  String? _selectedDayKey;

  // 🔄 প্রতিটা আলাদা দিনের আলাদা এক্সারসাইজের কমপ্লিশন স্টেট ট্র্যাক করার জন্য নেস্টেড ম্যাপ
  // স্ট্রাকচার: {'Monday': {0: true, 1: false}, 'Tuesday': {0: false}}
  final Map<String, Map<int, bool>> _dayCompletedExercises = {};

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'My Workout Plan 💪',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_charts')
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
                      Icons.fitness_center_rounded,
                      size: 64,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'আপনার জন্য এখনও কোনো ওয়ার্কআউট প্ল্যান তৈরি করা হয়নি। কোচের সাথে যোগাযোগ করুন। 🏋️‍♂️',
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

          // 📂 ফায়ারস্টোর থেকে নতুন 'day_routines' ম্যাপ রিসিভ করা
          Map<String, dynamic> dayRoutines = {};
          if (data['day_routines'] is Map) {
            dayRoutines = data['day_routines'] as Map<String, dynamic>;
          }

          // যদি কোনো ডেইস রুটিন না থাকে
          if (dayRoutines.isEmpty) {
            return const Center(
              child: Text(
                'কোনো রুটিন ডে খুঁজে পাওয়া যায়নি। ⚠️',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // ডাটাবেজের ডেইস কি (Keys) গুলোর লিস্ট তৈরি (যেমন: Monday, Day 1 ইত্যাদি)
          List<String> availableDays = dayRoutines.keys.toList();

          // শুরুতে যদি কোনো দিন সিলেক্ট করা না থাকে, তবে প্রথম দিনটি অটো-সিলেক্ট হবে
          if (_selectedDayKey == null ||
              !availableDays.contains(_selectedDayKey)) {
            _selectedDayKey = availableDays.first;
          }

          // সিলেক্টেড দিনের আন্ডারে থাকা এক্সারসাইজ লিস্ট রিড করা
          final currentDayData =
              dayRoutines[_selectedDayKey] as Map<String, dynamic>?;
          List<dynamic> exercises =
              (currentDayData != null && currentDayData['exercises'] is List)
              ? currentDayData['exercises']
              : [];

          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              const Text(
                'YOUR ROUTINE',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No Pain, No Gain!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 📅 দিন (Day Selector) ড্রপডাউন ফিল্টার বক্স
              const Text(
                "Select Training Day",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D29),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDayKey,
                    dropdownColor: const Color(0xFF1A1D29),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.blueAccent,
                    ),
                    items: availableDays.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(
                          day,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDayKey = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // মেইন আকর্ষণীয় ওয়ার্কআউট কার্ড
              Container(
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
                    // হেডার গ্রেডিয়েন্ট
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.purpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['workoutTitle'] ?? 'Workout Plan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['duration'] ?? 'Estimated Time',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.format_list_numbered_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${exercises.length} Exercises',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // এক্সারসাইজ লিস্ট অংশ (ডায়নামিক মডিউল 🛠️)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Target: $_selectedDayKey',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: Divider(color: Colors.white10),
                          ),

                          if (exercises.isEmpty)
                            const Text(
                              'এই দিনের জন্য কোনো এক্সারসাইজ যুক্ত করা হয়নি।',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            // নতুন অবজেক্ট লিস্ট জেনারেটর
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final exercise =
                                    exercises[index] as Map<String, dynamic>;

                                // 🛠️ নাল সেফটি নিশ্চিত করে চেকবক্সের স্টেট ডিফাইন করা (এরর ফিক্স)
                                final dayExercisesMap =
                                    _dayCompletedExercises[_selectedDayKey];
                                final isDone = dayExercisesMap != null
                                    ? (dayExercisesMap[index] ?? false)
                                    : false;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.blueAccent.withOpacity(0.04)
                                        : const Color(0xFF12141C),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDone
                                          ? Colors.blueAccent.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.02),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // কাস্টম চেকবক্স ইন্টিগ্রেশন
                                      Theme(
                                        data: ThemeData(
                                          unselectedWidgetColor: Colors.grey,
                                        ),
                                        child: Checkbox(
                                          value: isDone,
                                          activeColor: Colors.blueAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              // নেস্টেড ম্যাপ ইনিশিয়ালাইজেশন ব্যাকআপ
                                              if (_dayCompletedExercises[_selectedDayKey] ==
                                                  null) {
                                                _dayCompletedExercises[_selectedDayKey!] =
                                                    {};
                                              }
                                              _dayCompletedExercises[_selectedDayKey]![index] =
                                                  val ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // এক্সারসাইজ ডিটেইলস
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 10),
                                            Text(
                                              exercise['exerciseName'] ??
                                                  'Exercise',
                                              style: TextStyle(
                                                color: isDone
                                                    ? Colors.grey
                                                    : Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                decoration: isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 6),

                                            // Sets, Reps, Rest ব্যাজেস রো
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: [
                                                if (exercise['sets'] != null &&
                                                    exercise['sets']
                                                        .toString()
                                                        .isNotEmpty)
                                                  _buildStatBadge(
                                                    'Sets: ${exercise['sets']}',
                                                    Colors.blueAccent,
                                                  ),
                                                if (exercise['repsOrDuration'] !=
                                                        null &&
                                                    exercise['repsOrDuration']
                                                        .toString()
                                                        .isNotEmpty)
                                                  _buildStatBadge(
                                                    'Reps: ${exercise['repsOrDuration']}',
                                                    Colors.purpleAccent,
                                                  ),
                                                if (exercise['restTime'] !=
                                                        null &&
                                                    exercise['restTime']
                                                        .toString()
                                                        .isNotEmpty)
                                                  _buildStatBadge(
                                                    'Rest: ${exercise['restTime']}',
                                                    Colors.amber,
                                                  ),
                                              ],
                                            ),

                                            // কোচের ইনস্ট্রাকশন / ভিডিও লিংক বক্স
                                            if (exercise['instructionOrLink'] !=
                                                    null &&
                                                exercise['instructionOrLink']
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                '💡 Instruction: ${exercise['instructionOrLink']}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  fontSize: 12,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
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
            ],
          );
        },
      ),
    );
  }

  // ছোট ব্যাজ উইজেট
  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
