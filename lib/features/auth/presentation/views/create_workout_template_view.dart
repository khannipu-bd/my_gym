import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class CreateWorkoutTemplateView extends ConsumerStatefulWidget {
  const CreateWorkoutTemplateView({super.key});

  @override
  ConsumerState<CreateWorkoutTemplateView> createState() =>
      _CreateWorkoutTemplateViewState();
}

class _CreateWorkoutTemplateViewState
    extends ConsumerState<CreateWorkoutTemplateView> {
  final _templateNameController = TextEditingController();
  final _durationController = TextEditingController();

  List<DayRoutineControllers> _dayRoutines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addNewDayRoutine();
  }

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

  void _removeDayRoutine(int dayIndex) {
    if (_dayRoutines.length > 1) {
      setState(() {
        _dayRoutines[dayIndex].dispose();
        _dayRoutines.removeAt(dayIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one routine day is required! ⚠️'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  void _removeExerciseFromDay(int dayIndex, int exIndex) {
    if (_dayRoutines[dayIndex].exercises.length > 1) {
      setState(() {
        _dayRoutines[dayIndex].exercises[exIndex].dispose();
        _dayRoutines[dayIndex].exercises.removeAt(exIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one exercise is required per day! ⚠️'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Future<void> _saveWorkoutTemplate() async {
    final templateName = _templateNameController.text.trim();
    final duration = _durationController.text.trim();

    if (templateName.isEmpty || duration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Template Name and Duration! ⚠️'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> daysList = [];

    for (var day in _dayRoutines) {
      final dayName = day.dayNameController.text.trim();
      if (dayName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day/Focus name is required for all days! ⚠️'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> dayExercisesList = [];
      for (var ex in day.exercises) {
        final exName = ex.name.text.trim();
        if (exName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exercise name is required in "$dayName"! ⚠️'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        dayExercisesList.add({
          'exerciseName': exName,
          'sets': ex.sets.text.trim(),
          'repsOrDuration': ex.reps.text.trim(),
          'restTime': ex.rest.text.trim(),
          'instructionOrLink': ex.instruction.text.trim(),
        });
      }

      daysList.add({'dayName': dayName, 'exercises': dayExercisesList});
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('workout_templates').add({
        'templateName': templateName,
        'duration': duration,
        'days': daysList,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout Template Saved Successfully 🔥'),
            backgroundColor: Colors.blueAccent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save template: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTemplate(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Template',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete template "$name"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('workout_templates')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template "$name" deleted.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete template: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
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
          'Create Workout Template',
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
                  const Text(
                    'TEMPLATE DETAILS',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _templateNameController,
                    label: 'Workout Plan / Template Name',
                    hint: 'e.g., Weight Loss Beginner / Hypertrophy PPL',
                    icon: Icons.bookmark_added_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _durationController,
                    label: 'Overall Duration / Estimated Weeks',
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
                          color: Colors.purpleAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addNewDayRoutine(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.withOpacity(
                            0.15,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.add_to_photos_rounded,
                          color: Colors.purpleAccent,
                          size: 18,
                        ),
                        label: const Text(
                          'Add Day Routine',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                      onPressed: _isLoading ? null : _saveWorkoutTemplate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Workout Template',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  const Text(
                    'SAVED WORKOUT TEMPLATES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSavedTemplatesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildDayRoutineCard(int dayIndex) {
    final dayRoutine = _dayRoutines[dayIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.2),
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
                  hint: 'e.g., Day 1 / Chest & Triceps',
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
                      hint: 'e.g., Bench Press / Incline Dumbbell Press',
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
                      hint: 'Keep form straight / youtube URL',
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

  Widget _buildSavedTemplatesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workout_templates')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error loading templates: ${snapshot.error}',
            style: const TextStyle(color: Colors.redAccent),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No saved templates yet. Create your first template above!',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final templateName = data['templateName'] ?? 'Unnamed Template';
            final duration = data['duration'] ?? 'N/A';
            final days = (data['days'] is List) ? (data['days'] as List) : [];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D29),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: $duration • ${days.length} Days Routine',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    onPressed: () => _deleteTemplate(doc.id, templateName),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
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
