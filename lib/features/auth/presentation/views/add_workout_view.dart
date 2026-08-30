import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddWorkoutView extends StatefulWidget {
  const AddWorkoutView({super.key});

  @override
  State<AddWorkoutView> createState() => _AddWorkoutViewState();
}

// 📂 ডাটা মডেল: প্রতিটা সিঙ্গেল এক্সারসাইজের কন্ট্রোলার হোল্ডার
class ExerciseControllers {
  final TextEditingController name;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController rest;
  final TextEditingController instruction;

  ExerciseControllers({
    required String nameText,
    required String setsText,
    required String repsText,
    required String restText,
    required String instrText,
  }) : name = TextEditingController(text: nameText),
       sets = TextEditingController(text: setsText),
       reps = TextEditingController(text: repsText),
       rest = TextEditingController(text: restText),
       instruction = TextEditingController(text: instrText);

  void dispose() {
    name.dispose();
    sets.dispose();
    reps.dispose();
    rest.dispose();
    instruction.dispose();
  }
}

// 📂 ডাটা মডেল: প্রতিটা নির্দিষ্ট দিনের (Day Routine) কন্ট্রোলার হোল্ডার
class DayRoutineControllers {
  final TextEditingController dayNameController;
  List<ExerciseControllers> exercises;

  DayRoutineControllers({
    required String dayName,
    required List<ExerciseControllers> initialExercises,
  }) : dayNameController = TextEditingController(text: dayName),
       exercises = initialExercises;

  void dispose() {
    dayNameController.dispose();
    for (var ex in exercises) {
      ex.dispose();
    }
  }
}

class _AddWorkoutViewState extends State<AddWorkoutView> {
  String? _selectedUserEmail;
  String? _selectedUserName;

  final _workoutTitleController = TextEditingController();
  final _durationController = TextEditingController();

  // 📅 ডায়নামিক ডেইস এবং তাদের ভেতরের এক্সারসাইজ ট্র্যাক করার মেইন লিস্ট
  List<DayRoutineControllers> _dayRoutines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // শুরুতে ডিফল্টভাবে ১টি দিন এবং তার আন্ডারে ১টি এক্সারসাইজ ফিল্ড থাকবে
    _addNewDayRoutine();
  }

  // ➕ নতুন একটি দিন (Day) যোগ করার মেথড
  void _addNewDayRoutine({String dayName = ''}) {
    setState(() {
      _dayRoutines.add(
        DayRoutineControllers(
          dayName: dayName,
          initialExercises: [
            ExerciseControllers(
              nameText: '',
              setsText: '',
              repsText: '',
              restText: '',
              instrText: '',
            ),
          ],
        ),
      );
    });
  }

  // ➕ নির্দিষ্ট দিনের ভেতরে নতুন এক্সারসাইজ রো যুক্ত করার মেথড
  void _addExerciseToDay(
    int dayIndex, {
    String name = '',
    String sets = '',
    String reps = '',
    String rest = '',
    String instruction = '',
  }) {
    setState(() {
      _dayRoutines[dayIndex].exercises.add(
        ExerciseControllers(
          nameText: name,
          setsText: sets,
          repsText: reps,
          restText: rest,
          instrText: instruction,
        ),
      );
    });
  }

  // 🔄 ইউজার সিলেক্ট করার পর তার আগের ওয়ার্কআউট প্ল্যান ডাটাবেজ থেকে লোড করার মেথড
  Future<void> _fetchUserWorkoutData(String email) async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('workout_charts')
          .doc(email)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        _workoutTitleController.text = data['workoutTitle'] ?? '';
        _durationController.text = data['duration'] ?? '';

        // আগের সব কন্ট্রোলার ক্লিয়ার ও ডিসপোজ করা
        for (var day in _dayRoutines) {
          day.dispose();
        }
        _dayRoutines.clear();

        // ডাটাবেজ থেকে ডে বা দিনগুলোর রুটিন ম্যাপ রিড করা
        if (data['day_routines'] != null) {
          Map<String, dynamic> routinesMap = data['day_routines'];

          routinesMap.forEach((dayKey, dayData) {
            List<dynamic> exercisesData = dayData['exercises'] ?? [];
            List<ExerciseControllers> loadedExercises = [];

            for (var ex in exercisesData) {
              loadedExercises.add(
                ExerciseControllers(
                  nameText: ex['exerciseName'] ?? '',
                  setsText: ex['sets'] ?? '',
                  repsText: ex['repsOrDuration'] ?? '',
                  restText: ex['restTime'] ?? '',
                  instrText: ex['instructionOrLink'] ?? '',
                ),
              );
            }

            if (loadedExercises.isEmpty) {
              loadedExercises.add(
                ExerciseControllers(
                  nameText: '',
                  setsText: '',
                  repsText: '',
                  restText: '',
                  instrText: '',
                ),
              );
            }

            _dayRoutines.add(
              DayRoutineControllers(
                dayName: dayKey,
                initialExercises: loadedExercises,
              ),
            );
          });
        }

        if (_dayRoutines.isEmpty) {
          _addNewDayRoutine();
        }
      } else {
        _resetFormFieldsOnly();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ডাটা লোড করতে সমস্যা হয়েছে: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ❌ নির্দিষ্ট দিন (Day) ডিলিট করার মেথড
  void _removeDayRoutine(int dayIndex) {
    if (_dayRoutines.length > 1) {
      setState(() {
        _dayRoutines[dayIndex].dispose();
        _dayRoutines.removeAt(dayIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমপক্ষে একটি দিন (Day) থাকতে হবে! ⚠️')),
      );
    }
  }

  // ❌ নির্দিষ্ট দিনের ভেতর থেকে কোনো এক্সারসাইজ রিমুভ করার মেথড
  void _removeExerciseFromDay(int dayIndex, int exIndex) {
    if (_dayRoutines[dayIndex].exercises.length > 1) {
      setState(() {
        _dayRoutines[dayIndex].exercises[exIndex].dispose();
        _dayRoutines[dayIndex].exercises.removeAt(exIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('প্রতিটি দিনে কমপক্ষে একটি এক্সারসাইজ থাকতে হবে! ⚠️'),
        ),
      );
    }
  }

  // 🗑️ মেম্বারের সম্পূর্ণ ওয়ার্কআউট চার্ট ডেটাবেজ থেকে ডিলিট করার মেথড
  Future<void> _deleteEntireWorkoutPlan() async {
    if (_selectedUserEmail == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        title: const Text(
          'প্ল্যান ডিলিট করুন 🚨',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'আপনি কি নিশ্চিত যে $_selectedUserName এর সম্পূর্ণ ওয়ার্কআউট প্ল্যানটি ডিলিট করতে চান?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance
                    .collection('workout_charts')
                    .doc(_selectedUserEmail)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$_selectedUserName এর প্ল্যানটি ডিলিট করা হয়েছে। 🧹',
                      ),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  _clearForm();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ডিলিট করতে সমস্যা হয়েছে: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFormFieldsOnly() {
    _workoutTitleController.clear();
    _durationController.clear();
    for (var day in _dayRoutines) {
      day.dispose();
    }
    _dayRoutines.clear();
    _addNewDayRoutine();
  }

  void _clearForm() {
    setState(() {
      _selectedUserEmail = null;
      _selectedUserName = null;
      _resetFormFieldsOnly();
    });
  }

  // ☁️ ফায়ারস্টোরে ডেটা আপলোড করার মূল মেথড
  Future<void> _uploadWorkoutChart() async {
    final email = _selectedUserEmail;
    final workoutTitle = _workoutTitleController.text.trim();
    final duration = _durationController.text.trim();

    if (email == null || workoutTitle.isEmpty || duration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'মেম্বার সিলেক্ট করুন এবং সবগুলো প্রধান ঘর পূরণ করুন! ⚠️',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // স্ট্রাকচার্ড ডাটা ম্যাপ জেনারেট করা
    Map<String, dynamic> dayRoutinesMap = {};

    for (var day in _dayRoutines) {
      final dayName = day.dayNameController.text.trim();
      if (dayName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'সবগুলো দিনের নাম (e.g., Day 1 / Monday) দেওয়া বাধ্যতামূলক! ⚠️',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> dayExercisesList = [];
      for (var ex in day.exercises) {
        final name = ex.name.text.trim();
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$dayName" এ এক্সারসাইজের নাম দেওয়া বাধ্যতামূলক! ⚠️',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        dayExercisesList.add({
          'exerciseName': name,
          'sets': ex.sets.text.trim(),
          'repsOrDuration': ex.reps.text.trim(),
          'restTime': ex.rest.text.trim(),
          'instructionOrLink': ex.instruction.text.trim(),
        });
      }

      dayRoutinesMap[dayName] = {'exercises': dayExercisesList};
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('workout_charts')
          .doc(email)
          .set({
            'userEmail': email,
            'workoutTitle': workoutTitle,
            'duration': duration,
            'day_routines':
                dayRoutinesMap, // 👈 সাব-ম্যাপ হিসেবে সম্পূর্ণ ডেইস ডাটা যুক্ত হলো
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ওয়ার্কআউট প্ল্যান সফলভাবে আপডেট হয়েছে! 🔥'),
            backgroundColor: Colors.blueAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ভুল হয়েছে: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _workoutTitleController.dispose();
    _durationController.dispose();
    for (var day in _dayRoutines) {
      day.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Assign Workout Plan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'UPDATE MEMBER WORKOUT',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (_selectedUserEmail != null)
                        IconButton(
                          onPressed: _deleteEntireWorkoutPlan,
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          tooltip: 'Delete full plan from DB',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Select Member",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator(
                          color: Colors.blueAccent,
                        );
                      }

                      var userDocs = snapshot.data!.docs;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D29),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUserEmail,
                            hint: const Text(
                              'সিলেক্ট মেম্বার',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            dropdownColor: const Color(0xFF1A1D29),
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: userDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final email = data['email'] ?? '';
                              final name = data['name'] ?? 'Unknown Member';
                              return DropdownMenuItem<String>(
                                value: email,
                                child: Text('$name ($email)'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final selectedDoc = userDocs.firstWhere(
                                  (doc) =>
                                      (doc.data()
                                          as Map<String, dynamic>)['email'] ==
                                      value,
                                );
                                final selectedData =
                                    selectedDoc.data() as Map<String, dynamic>;
                                setState(() {
                                  _selectedUserEmail = value;
                                  _selectedUserName =
                                      selectedData['name'] ?? 'Unknown Member';
                                });
                                _fetchUserWorkoutData(value);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _workoutTitleController,
                    label: 'Workout Routine Title',
                    hint: 'e.g., 5-Day Split / Beginner Routine',
                    icon: Icons.fitness_center_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _durationController,
                    label: 'Overall Duration / Est. Weeks',
                    hint: 'e.g., 12 Weeks',
                    icon: Icons.calendar_month_rounded,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ROUTINE DAYS',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addNewDayRoutine(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withOpacity(0.15),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.add_to_photos_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        label: const Text(
                          'Add Day Plan',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 📅 ডেইস এবং তাদের ভেতরের এক্সারসাইজ কার্ডস লিস্ট জেনারেশন
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dayRoutines.length,
                    itemBuilder: (context, dayIndex) {
                      return _buildDayRoutineCard(dayIndex);
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _uploadWorkoutChart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Update Workout Plan',
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
  }

  // 🕋 প্রতিটা সিঙ্গেল ডে (Day) কন্ট্রোলার উইজেট কার্ড
  Widget _buildDayRoutineCard(int dayIndex) {
    final dayRoutine = _dayRoutines[dayIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: dayRoutine.dayNameController,
                  label: 'Day / Focus Name',
                  hint: 'e.g., Monday / Chest Day',
                  icon: Icons.view_day_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeDayRoutine(dayIndex),
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                  size: 26,
                ),
                tooltip: 'Remove Day',
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercises under this day:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addExerciseToDay(dayIndex),
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.greenAccent,
                  size: 18,
                ),
                label: const Text(
                  'Add Exercise',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🏋️‍♂️ ওই নির্দিষ্ট ডেইস-এর ভেতরের এক্সারসাইজ সমূহের তালিকা
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayRoutine.exercises.length,
            itemBuilder: (context, exIndex) {
              final exControllers = dayRoutine.exercises[exIndex];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF12141C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercise #${exIndex + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _removeExerciseFromDay(dayIndex, exIndex),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildExerciseSubField(
                      controller: exControllers.name,
                      label: 'Exercise Name',
                      hint: 'e.g., Bench Press / Squats',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildExerciseSubField(
                            controller: exControllers.sets,
                            label: 'Sets',
                            hint: '4',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: _buildExerciseSubField(
                            controller: exControllers.reps,
                            label: 'Reps / Duration',
                            hint: '12 reps / 15 mins',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildExerciseSubField(
                            controller: exControllers.rest,
                            label: 'Rest',
                            hint: '60s',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildExerciseSubField(
                      controller: exControllers.instruction,
                      label: 'Instruction / Video Link (Optional)',
                      hint: 'Keep form straight / youtube url',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildExerciseSubField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.1),
          fontSize: 12,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.2),
        ),
      ),
    );
  }
}
