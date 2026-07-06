import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddWorkoutView extends StatefulWidget {
  const AddWorkoutView({super.key});

  @override
  State<AddWorkoutView> createState() => _AddWorkoutViewState();
}

class _AddWorkoutViewState extends State<AddWorkoutView> {
  final _emailController = TextEditingController();
  final _workoutTitleController =
      TextEditingController(); // যেমন: Chest & Triceps Day
  final _durationController = TextEditingController(); // যেমন: 60 Mins
  final _exercisesController =
      TextEditingController(); // যেমন: 5 Exercises বা পুরো লিস্ট

  bool _isLoading = false;

  Future<void> _uploadWorkoutChart() async {
    final email = _emailController.text.trim().toLowerCase();
    final workoutTitle = _workoutTitleController.text.trim();
    final duration = _durationController.text.trim();
    final exercises = _exercisesController.text.trim();

    if (email.isEmpty ||
        workoutTitle.isEmpty ||
        duration.isEmpty ||
        exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সবগুলো ঘর পূরণ করুন! ⚠️'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // workout_charts কালেকশনে ইমেইল আইডি দিয়ে সেভ হবে
      await FirebaseFirestore.instance
          .collection('workout_charts')
          .doc(email)
          .set({
            'userEmail': email,
            'workoutTitle': workoutTitle,
            'duration': duration,
            'exercises': exercises,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ওয়ার্কআউট প্ল্যান সফলভাবে আপডেট হয়েছে! 🔥'),
            backgroundColor: Colors.blueAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ভুল হয়েছে: $e'),
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
    _emailController.dispose();
    _workoutTitleController.dispose();
    _durationController.dispose();
    _exercisesController.dispose();
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            _buildInputField(
              controller: _emailController,
              label: "Member's Email Address",
              hint: "user@email.com",
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _workoutTitleController,
              label: 'Workout Routine Name',
              hint: 'e.g., Chest & Triceps Day / Push Day',
              icon: Icons.fitness_center_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _durationController,
              label: 'Duration / Est. Time',
              hint: 'e.g., 60 Mins • 5 Exercises',
              icon: Icons.timer_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _exercisesController,
              label: 'Exercise Details / List',
              hint:
                  '1. Bench Press: 4 Sets x 12 Reps\n2. Incline Dumbbell Press: 3 Sets...',
              icon: Icons.format_list_bulleted_rounded,
              maxLines: 6,
            ),
            const SizedBox(height: 32),
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
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}
