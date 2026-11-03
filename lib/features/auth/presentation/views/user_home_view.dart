// user_home_view.dart
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_view.dart';
import 'user_diet_view.dart';
import 'user_workout_view.dart';
import '../../../../core/services/app_update_service.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF161924).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.fitness_center_rounded, 'Workouts'),
                  _buildNavItem(2, Icons.restaurant_rounded, 'Diet'),
                  _buildNavItem(3, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF64748B),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final String currentUserEmail =
      FirebaseAuth.instance.currentUser?.email ?? "";
  late TabController _tabController;

  // 🚶 Pedometer & Live Step Counter Variables
  StreamSubscription<StepCount>? _stepCountSubscription;
  int _todaySteps = 0;
  bool _isPedSensorAvailable = true;

  // 💧 Water & Workout Completion Tracking
  double _loggedWater = 0.0;
  Map<int, bool> _completedExercises = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initAsyncServices();
      }
    });
  }

  void _initAsyncServices() {
    _loadStoredData();
    _initSensorsSafely();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Read stored water intake with key water_intake_YYYY-MM-DD
    final savedWater =
        prefs.getDouble('water_intake_$todayStr') ??
        prefs.getDouble('water_logged_$todayStr') ??
        0.0;

    final completedKeys =
        prefs.getStringList('completed_exercises_$todayStr') ?? [];
    final Map<int, bool> loadedMap = {};
    for (var key in completedKeys) {
      final idx = int.tryParse(key);
      if (idx != null) {
        loadedMap[idx] = true;
      }
    }

    if (mounted) {
      setState(() {
        _loggedWater = savedWater;
        _completedExercises = loadedMap;
      });
    }
  }

  Future<void> _logWaterGlass() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final updated = (_loggedWater + 0.25).clamp(0.0, 10.0);
    await prefs.setDouble('water_intake_$todayStr', updated);
    await prefs.setDouble('water_logged_$todayStr', updated);
    if (mounted) {
      setState(() {
        _loggedWater = updated;
      });
    }
  }

  Future<void> _resetWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setDouble('water_intake_$todayStr', 0.0);
    await prefs.setDouble('water_logged_$todayStr', 0.0);
    if (mounted) {
      setState(() {
        _loggedWater = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Water intake reset to 0 L 💧'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleExercise(int index, bool isDone) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    setState(() {
      _completedExercises[index] = isDone;
    });

    final activeList = _completedExercises.entries
        .where((e) => e.value)
        .map((e) => e.key.toString())
        .toList();

    await prefs.setStringList('completed_exercises_$todayStr', activeList);
  }

  // 💧 Dynamic Water Target Calculation Formula
  double _calculateDynamicWaterTarget({
    required double userWeightKg,
    required Map<String, dynamic>? workoutData,
    required Map<String, dynamic> parsedWorkout,
  }) {
    // 1. Safe weight fallback (default 65 kg if missing or <= 0)
    final double weightKg = (userWeightKg > 0) ? userWeightKg : 65.0;

    // 2. Base target: user_weight_kg * 35 ml
    final double baseWaterMl = weightKg * 35.0;

    // 3. Add workout adjustment: +350 ml if workout is assigned for today
    final List<dynamic> exercises = parsedWorkout['exercises'] ?? [];
    final bool hasWorkoutToday =
        exercises.isNotEmpty ||
        (workoutData != null &&
            workoutData.isNotEmpty &&
            parsedWorkout['title'] != 'Rest & Recovery Day 😴');
    final double workoutAdjustmentMl = hasWorkoutToday ? 350.0 : 0.0;

    // 4. Clamp target between 1500 ml and 4500 ml
    final double totalTargetMl = (baseWaterMl + workoutAdjustmentMl).clamp(
      1500.0,
      4500.0,
    );

    // 5. Convert to Liters (rounded to 1 decimal, e.g. 2.6 L)
    return double.parse((totalTargetMl / 1000.0).toStringAsFixed(1));
  }

  // 👟 Safe Pedometer & Sensor Initialization
  Future<void> _initSensorsSafely() async {
    try {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isPedSensorAvailable = false;
            _todaySteps = 0;
          });
        }
        return;
      }

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (dynamic error) {
          debugPrint('Pedometer stream error: $error');
          _onStepCountError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Pedometer sensor init exception: $e');
      if (mounted) {
        setState(() {
          _isPedSensorAvailable = false;
          _todaySteps = 0;
        });
      }
    }
  }

  void _onStepCount(StepCount event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final savedDate = prefs.getString('step_baseline_date');
      final savedBaseline = prefs.getInt('step_baseline_count');

      int baseline = event.steps;

      if (savedDate == todayStr && savedBaseline != null) {
        if (event.steps < savedBaseline) {
          baseline = event.steps;
          await prefs.setString('step_baseline_date', todayStr);
          await prefs.setInt('step_baseline_count', baseline);
        } else {
          baseline = savedBaseline;
        }
      } else {
        await prefs.setString('step_baseline_date', todayStr);
        await prefs.setInt('step_baseline_count', event.steps);
        baseline = event.steps;
      }

      final calculatedSteps = (event.steps - baseline).clamp(0, 999999);

      if (mounted) {
        setState(() {
          _todaySteps = calculatedSteps;
          _isPedSensorAvailable = true;
        });
      }
    } catch (e) {
      debugPrint('Step count processing exception: $e');
      if (mounted) {
        setState(() {
          _isPedSensorAvailable = false;
        });
      }
    }
  }

  void _onStepCountError(dynamic error) {
    if (mounted) {
      setState(() {
        _isPedSensorAvailable = false;
        _todaySteps = 0;
      });
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  double _parseHeightInInches(String heightStr) {
    if (heightStr.isEmpty || heightStr == "0.0") return 0.0;
    try {
      final clean = heightStr.replaceAll('"', '').replaceAll("'", '.').trim();
      if (clean.contains('.')) {
        final parts = clean.split('.');
        int feet = int.tryParse(parts[0]) ?? 0;
        int inches = int.tryParse(parts[1]) ?? 0;
        return (feet * 12.0) + inches;
      } else {
        double val = double.tryParse(clean) ?? 0.0;
        if (val > 100) {
          return val / 2.54;
        } else {
          return val * 12.0;
        }
      }
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, dynamic> _calculateMetrics(String heightStr, double weightKg) {
    double totalInches = _parseHeightInInches(heightStr);
    if (weightKg <= 0 || totalInches <= 0) {
      return {
        'hasData': false,
        'bmi': 0.0,
        'bmr': 0,
        'status': 'No Profile Data',
        'categoryTag': 'No Data',
        'color': Colors.grey,
        'displayHeightWeight': 'No Profile Data',
        'burnGoal': 450,
        'stepsGoal': 6000,
      };
    }

    double heightMeters = totalInches * 0.0254;
    double bmi = weightKg / (heightMeters * heightMeters);
    bmi = double.parse(bmi.toStringAsFixed(1));

    double heightCm = totalInches * 2.54;
    int bmr = ((10 * weightKg) + (6.25 * heightCm) - (5 * 25) + 5)
        .round()
        .clamp(500, 4000);

    String status;
    String categoryTag;
    Color color;
    int burnGoal = 450;
    int stepsGoal = 6000;

    if (bmi < 18.5) {
      status = 'Underweight 🦴';
      categoryTag = 'Underweight';
      color = const Color(0xFF38BDF8);
      burnGoal = 350;
      stepsGoal = 6000;
    } else if (bmi >= 18.5 && bmi < 25.0) {
      status = 'Healthy ✨';
      categoryTag = 'Healthy';
      color = const Color(0xFF10B981);
      burnGoal = 450;
      stepsGoal = 6000;
    } else if (bmi >= 25.0 && bmi < 30.0) {
      status = 'Overweight ⚠️';
      categoryTag = 'Overweight';
      color = const Color(0xFFF59E0B);
      burnGoal = 550;
      stepsGoal = 8000;
    } else {
      status = 'Obese 🚨';
      categoryTag = 'Obese';
      color = const Color(0xFFEF4444);
      burnGoal = 650;
      stepsGoal = 10000;
    }

    int feet = (totalInches / 12).floor();
    int inches = (totalInches % 12).round();

    return {
      'hasData': true,
      'bmi': bmi,
      'bmr': bmr,
      'status': status,
      'categoryTag': categoryTag,
      'color': color,
      'displayHeightWeight': "$feet'$inches\" • ${weightKg.toInt()} kg",
      'burnGoal': burnGoal,
      'stepsGoal': stepsGoal,
    };
  }

  void _showDigitalQrPassModal(
    BuildContext context,
    String userName,
    String planName,
    String daysLeftText,
    bool isActive,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D29),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isActive
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : Colors.redAccent.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? const Color(0xFF10B981) : Colors.redAccent)
                  .withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SPARTAN DIGITAL PASS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Member ID: ${userId.length > 8 ? userId.substring(0, 8).toUpperCase() : userId.toUpperCase()}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$planName • $daysLeftText',
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 160,
                    color: Color(0xFF12141C),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan at turnstile or reception desk for instant entry',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showQuickProfileModal(BuildContext context) {
    final heightController = TextEditingController();
    final weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D29),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Setup Profile Data 🎯',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your height & weight to calculate live BMI & BMR burn targets.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Height (e.g. 5.9 for 5\'9")',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF12141C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.height,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Weight in kg (e.g. 72)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF12141C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.monitor_weight_outlined,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final h = heightController.text.trim();
                    final w =
                        double.tryParse(weightController.text.trim()) ?? 0.0;
                    if (h.isNotEmpty && w > 0 && currentUserId.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .update({'height': h, 'weight': w});
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Save & Calculate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodayWorkoutBottomSheet(
    BuildContext context,
    String routineTitle,
    List<dynamic> exercises,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          int doneCount = _completedExercises.values
              .where((v) => v == true)
              .length;
          int totalCount = exercises.length;
          double progress = totalCount > 0
              ? (doneCount / totalCount).clamp(0.0, 1.0)
              : 0.0;
          int percent = (progress * 100).toInt();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D29),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "TODAY'S WORKOUT",
                                  style: TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  routineTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$doneCount of $totalCount Completed',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFA78BFA),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: exercises.isEmpty
                      ? const Center(
                          child: Text(
                            'No exercises scheduled for today.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final ex = exercises[index] as Map<String, dynamic>;
                            final bool isDone =
                                _completedExercises[index] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? const Color(
                                        0xFF8B5CF6,
                                      ).withValues(alpha: 0.08)
                                    : const Color(0xFF12141C),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDone
                                      ? const Color(
                                          0xFF8B5CF6,
                                        ).withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      unselectedWidgetColor: Colors.grey,
                                    ),
                                    child: Checkbox(
                                      value: isDone,
                                      activeColor: const Color(0xFF8B5CF6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (val) {
                                        _toggleExercise(index, val ?? false);
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex['exerciseName'] ?? 'Exercise',
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
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            if (ex['sets'] != null &&
                                                ex['sets']
                                                    .toString()
                                                    .isNotEmpty)
                                              _buildMiniBadge(
                                                'Sets: ${ex['sets']}',
                                                Colors.blueAccent,
                                              ),
                                            if (ex['repsOrDuration'] != null &&
                                                ex['repsOrDuration']
                                                    .toString()
                                                    .isNotEmpty)
                                              _buildMiniBadge(
                                                'Reps: ${ex['repsOrDuration']}',
                                                Colors.purpleAccent,
                                              ),
                                            if (ex['restTime'] != null &&
                                                ex['restTime']
                                                    .toString()
                                                    .isNotEmpty)
                                              _buildMiniBadge(
                                                'Rest: ${ex['restTime']}s',
                                                Colors.amber,
                                              ),
                                          ],
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _parseWorkoutData(Map<String, dynamic>? workoutData) {
    if (workoutData == null || workoutData.isEmpty) {
      return {
        'title': 'Rest Day 🧘',
        'subtitle': 'No active scheduled workout',
        'exercises': <dynamic>[],
      };
    }

    final overallTitle = workoutData['workoutTitle'] ?? 'Workout Plan';
    Map<String, dynamic> dayRoutines = {};
    if (workoutData['day_routines'] is Map) {
      dayRoutines = Map<String, dynamic>.from(workoutData['day_routines']);
    }

    final now = DateTime.now();
    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final todayDayName = daysOfWeek[now.weekday - 1];

    String? matchingKey;
    for (var key in dayRoutines.keys) {
      if (key.toLowerCase().contains(todayDayName.toLowerCase()) ||
          todayDayName.toLowerCase().contains(key.toLowerCase())) {
        matchingKey = key;
        break;
      }
    }

    matchingKey ??= dayRoutines.isNotEmpty ? dayRoutines.keys.first : null;

    if (matchingKey != null && dayRoutines[matchingKey] is Map) {
      final routine = Map<String, dynamic>.from(dayRoutines[matchingKey]);
      final exercises = routine['exercises'] is List
          ? routine['exercises'] as List
          : [];
      final dayTitle = routine['dayTitle'] ?? matchingKey;
      return {
        'title': '$overallTitle • $dayTitle',
        'subtitle': '$dayTitle Routine (${exercises.length} Exercises)',
        'exercises': exercises,
      };
    }

    if (workoutData['exercises'] is List) {
      final exercises = workoutData['exercises'] as List;
      return {
        'title': overallTitle,
        'subtitle': '${exercises.length} Exercises',
        'exercises': exercises,
      };
    }

    return {
      'title': 'Rest Day 🧘',
      'subtitle': 'Take time to rest and rebuild',
      'exercises': <dynamic>[],
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
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'lib/assets/images/app_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SPARTAN GYM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notices')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
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
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
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
                            fontSize: 10,
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
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1A1D29),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          color: Colors.purpleAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Notice Board',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notices')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.purpleAccent,
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNoticeList(docs, 'all'),
                        _buildNoticeList(docs, 'unread'),
                        _buildNoticeList(docs, 'read'),
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
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
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

            if (userData['expiryDate'] is Timestamp) {
              final Timestamp expiryTimestamp =
                  userData['expiryDate'] as Timestamp;
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

          final metrics = _calculateMetrics(rawHeight, userWeight);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HERO GREETING
                Text(
                  'Welcome back, $userName! 🔥',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Time to Smash Your Goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),

                // 2. CYBER DARK METALLIC MEMBERSHIP CARD
                GestureDetector(
                  onTap: () => _showDigitalQrPassModal(
                    context,
                    userName,
                    planName,
                    daysLeftText,
                    isActive,
                    currentUserId,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF161922), Color(0xFF1E2230)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : Colors.redAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.redAccent)
                                  .withValues(alpha: 0.12),
                          blurRadius: 18,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                (isActive
                                        ? const Color(0xFF10B981)
                                        : Colors.redAccent)
                                    .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  (isActive
                                          ? const Color(0xFF10B981)
                                          : Colors.redAccent)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            isActive
                                ? Icons.verified_user_rounded
                                : Icons.gpp_bad_rounded,
                            color: isActive
                                ? const Color(0xFF10B981)
                                : Colors.redAccent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACTIVE GYM MEMBERSHIP',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF10B981)
                                          : Colors.redAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isActive
                                                      ? const Color(0xFF10B981)
                                                      : Colors.redAccent)
                                                  .withValues(alpha: 0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    daysLeftText,
                                    style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFF34D399)
                                          : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'QR Pass',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. DUAL METRICS HUB: BMI & BMR GLASS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D29),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: metrics['hasData'] == false
                      ? Row(
                          children: [
                            const Icon(
                              Icons.monitor_weight_outlined,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Profile Metrics Incomplete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Setup height & weight for live BMI & BMR.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showQuickProfileModal(context),
                              child: const Text(
                                'Setup ->',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // LEFT SIDE: BMI
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.accessibility_new_rounded,
                                        color: metrics['color'],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'BMI Index',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        metrics['bmi'].toString(),
                                        style: TextStyle(
                                          color: metrics['color'],
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (metrics['color'] as Color)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          metrics['categoryTag'],
                                          style: TextStyle(
                                            color: metrics['color'],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    metrics['displayHeightWeight'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF38BDF8),
                                            Color(0xFF10B981),
                                            Color(0xFFF59E0B),
                                            Color(0xFFEF4444),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 80,
                              width: 1,
                              color: Colors.white10,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // RIGHT SIDE: BMR
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Color(0xFFF97316),
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'BMR Burn',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${metrics['bmr']} kcal',
                                    style: const TextStyle(
                                      color: Color(0xFFF97316),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Base Daily Burn',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Est. calories at rest',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 20),

                // 4. "TODAY'S WORKOUT" INTERACTIVE FOCUS CARD & 5. STAT WIDGETS
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('workout_charts')
                      .doc(currentUserEmail)
                      .snapshots(),
                  builder: (context, workoutSnapshot) {
                    Map<String, dynamic>? workoutData;
                    if (workoutSnapshot.hasData &&
                        workoutSnapshot.data!.exists) {
                      workoutData =
                          workoutSnapshot.data!.data() as Map<String, dynamic>?;
                    }

                    final parsedWorkout = _parseWorkoutData(workoutData);
                    final String routineTitle = parsedWorkout['title'];
                    final List<dynamic> exercises = parsedWorkout['exercises'];

                    int totalExercises = exercises.length;
                    int doneExercises = _completedExercises.values
                        .where((v) => v == true)
                        .length;
                    if (doneExercises > totalExercises) {
                      doneExercises = totalExercises;
                    }

                    double progress = totalExercises > 0
                        ? (doneExercises / totalExercises).clamp(0.0, 1.0)
                        : 0.0;
                    int progressPercent = (progress * 100).toInt();

                    // Calculate Dynamic Water Target
                    final double dynamicWaterTarget =
                        _calculateDynamicWaterTarget(
                          userWeightKg: userWeight,
                          workoutData: workoutData,
                          parsedWorkout: parsedWorkout,
                        );

                    final int loggedGlasses = (_loggedWater / 0.25).round();
                    final int targetGlasses =
                        ((dynamicWaterTarget * 1000) / 250).round();

                    final int activeBurnKcal = (_todaySteps * 0.04).round();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FOCUS WORKOUT CARD
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1F1C38), Color(0xFF181A26)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                if (exercises.isNotEmpty) {
                                  _showTodayWorkoutBottomSheet(
                                    context,
                                    routineTitle,
                                    exercises,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.bolt_rounded,
                                                color: Color(0xFFA78BFA),
                                                size: 16,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "TODAY'S ROUTINE",
                                                style: TextStyle(
                                                  color: Color(0xFFA78BFA),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            routineTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            totalExercises > 0
                                                ? "$doneExercises of $totalExercises Exercises Done ($progressPercent%)"
                                                : "Rest & recovery focus",
                                            style: const TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (totalExercises > 0) ...[
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor: Colors.white10,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFFA78BFA)),
                                                minHeight: 5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF8B5CF6),
                                            Color(0xFF6366F1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF8B5CF6,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            totalExercises > 0
                                                ? (progressPercent == 100
                                                      ? "Completed"
                                                      : "Start")
                                                : "View",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // 5. INTERACTIVE ACTIVITY & BURN STAT WIDGETS
                        const Text(
                          "TODAY'S TARGETS",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // BURN CARD
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D29),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF97316,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          color: Color(0xFFF97316),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Burned Calories',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Burned: $activeBurnKcal kcal',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'from $_todaySteps steps',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            (activeBurnKcal /
                                                    (metrics['burnGoal']
                                                        as int))
                                                .clamp(0.0, 1.0),
                                        backgroundColor: Colors.white10,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFFF97316),
                                            ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // WATER TARGET CARD
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D29),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF06B6D4,
                                    ).withValues(alpha: 0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF06B6D4,
                                      ).withValues(alpha: 0.08),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF06B6D4,
                                            ).withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.water_drop_rounded,
                                            color: Color(0xFF06B6D4),
                                            size: 18,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _logWaterGlass,
                                          onLongPress: _resetWaterIntake,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF06B6D4,
                                              ).withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF06B6D4,
                                                ).withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: Color(0xFF06B6D4),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Water Intake',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_loggedWater.toStringAsFixed(1)} L / ${dynamicWaterTarget.toStringAsFixed(1)} L',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$loggedGlasses / $targetGlasses Glasses',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            (_loggedWater / dynamicWaterTarget)
                                                .clamp(0.0, 1.0),
                                        backgroundColor: Colors.white10,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF06B6D4),
                                            ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // STEPS GOAL CARD
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D29),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _isPedSensorAvailable
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.25)
                                        : Colors.white10,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Icon(
                                          Icons.directions_walk_rounded,
                                          color: Color(0xFF10B981),
                                          size: 22,
                                        ),
                                        if (_isPedSensorAvailable)
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Steps Goal',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isPedSensorAvailable
                                          ? '$_todaySteps'
                                          : '0 Steps / Sensor Idle',
                                      style: TextStyle(
                                        color: _isPedSensorAvailable
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: _isPedSensorAvailable
                                            ? 14
                                            : 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isPedSensorAvailable
                                          ? 'Goal: ${metrics['stepsGoal']}'
                                          : 'Manual/0 Steps',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _isPedSensorAvailable
                                            ? (_todaySteps /
                                                      (metrics['stepsGoal']
                                                          as int))
                                                  .clamp(0.0, 1.0)
                                            : 0.0,
                                        backgroundColor: Colors.white10,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _isPedSensorAvailable
                                                  ? const Color(0xFF10B981)
                                                  : Colors.grey,
                                            ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
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
                  : Colors.purpleAccent.withValues(alpha: 0.3),
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
}
