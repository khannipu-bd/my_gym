import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateDietTemplateView extends ConsumerStatefulWidget {
  const CreateDietTemplateView({super.key});

  @override
  ConsumerState<CreateDietTemplateView> createState() =>
      _CreateDietTemplateViewState();
}

class _CreateDietTemplateViewState
    extends ConsumerState<CreateDietTemplateView> {
  final _templateNameController = TextEditingController();

  // Breakfast controllers
  final _breakfastFoodController = TextEditingController();
  final _breakfastNoteController = TextEditingController();
  final _breakfastKcalController = TextEditingController();

  // Lunch controllers
  final _lunchFoodController = TextEditingController();
  final _lunchNoteController = TextEditingController();
  final _lunchKcalController = TextEditingController();

  // Dinner controllers
  final _dinnerFoodController = TextEditingController();
  final _dinnerNoteController = TextEditingController();
  final _dinnerKcalController = TextEditingController();

  // Snack controllers
  final _snackFoodController = TextEditingController();
  final _snackNoteController = TextEditingController();
  final _snackKcalController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _templateNameController.dispose();

    _breakfastFoodController.dispose();
    _breakfastNoteController.dispose();
    _breakfastKcalController.dispose();

    _lunchFoodController.dispose();
    _lunchNoteController.dispose();
    _lunchKcalController.dispose();

    _dinnerFoodController.dispose();
    _dinnerNoteController.dispose();
    _dinnerKcalController.dispose();

    _snackFoodController.dispose();
    _snackNoteController.dispose();
    _snackKcalController.dispose();

    super.dispose();
  }

  Future<void> _saveDietTemplate() async {
    final templateName = _templateNameController.text.trim();

    if (templateName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Diet Template Name! ⚠️'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final breakfastFood = _breakfastFoodController.text.trim();
    final lunchFood = _lunchFoodController.text.trim();
    final dinnerFood = _dinnerFoodController.text.trim();
    final snackFood = _snackFoodController.text.trim();

    if (breakfastFood.isEmpty &&
        lunchFood.isEmpty &&
        dinnerFood.isEmpty &&
        snackFood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out at least one meal section! ⚠️'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final breakfastMap = {
        'food': breakfastFood,
        'note': _breakfastNoteController.text.trim(),
        'kcal': _breakfastKcalController.text.trim(),
      };
      final lunchMap = {
        'food': lunchFood,
        'note': _lunchNoteController.text.trim(),
        'kcal': _lunchKcalController.text.trim(),
      };
      final dinnerMap = {
        'food': dinnerFood,
        'note': _dinnerNoteController.text.trim(),
        'kcal': _dinnerKcalController.text.trim(),
      };
      final snackMap = {
        'food': snackFood,
        'note': _snackNoteController.text.trim(),
        'kcal': _snackKcalController.text.trim(),
      };

      await FirebaseFirestore.instance.collection('diet_templates').add({
        'templateName': templateName,
        'createdAt': FieldValue.serverTimestamp(),
        'meals': {
          'breakfast': breakfastMap,
          'lunch': lunchMap,
          'dinner': dinnerMap,
          'snack': snackMap,
        },
        'breakfast': breakfastMap,
        'lunch': lunchMap,
        'dinner': dinnerMap,
        'snack': snackMap,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diet Template Saved Successfully! 🥗'),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Create Diet Plan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card - Template Name
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D29),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.bookmark_added_rounded,
                              color: Colors.greenAccent,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Template Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _templateNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Diet Plan / Template Name',
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            hintText:
                                'e.g., Keto Cut, High Protein Bulk, Weight Loss Clean',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF12141C),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.greenAccent,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'MEAL SECTIONS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🍳 Breakfast Section
                  _buildMealSection(
                    title: 'Breakfast Menu',
                    foodController: _breakfastFoodController,
                    noteController: _breakfastNoteController,
                    kcalController: _breakfastKcalController,
                    icon: Icons.wb_sunny_rounded,
                    accentColor: Colors.amberAccent,
                    foodHint: 'e.g. 3 Egg Whites, 1 Bowl Oats, 5 Almonds',
                  ),

                  // 🍱 Lunch Section
                  _buildMealSection(
                    title: 'Lunch Menu',
                    foodController: _lunchFoodController,
                    noteController: _lunchNoteController,
                    kcalController: _lunchKcalController,
                    icon: Icons.wb_twilight_rounded,
                    accentColor: Colors.orangeAccent,
                    foodHint:
                        'e.g. 200g Grilled Chicken, 1 Cup Brown Rice, Salad',
                  ),

                  // 🍽️ Dinner Section
                  _buildMealSection(
                    title: 'Dinner Menu',
                    foodController: _dinnerFoodController,
                    noteController: _dinnerNoteController,
                    kcalController: _dinnerKcalController,
                    icon: Icons.dark_mode_rounded,
                    accentColor: Colors.purpleAccent,
                    foodHint: 'e.g. 150g Fish/Tofu, Boiled Vegetables',
                  ),

                  // ☕ Snack Section
                  _buildMealSection(
                    title: 'Snack / Evening Menu',
                    foodController: _snackFoodController,
                    noteController: _snackNoteController,
                    kcalController: _snackKcalController,
                    icon: Icons.local_cafe_rounded,
                    accentColor: Colors.tealAccent,
                    foodHint: 'e.g. 1 Scoop Whey Protein, Green Tea, Apple',
                  ),

                  const SizedBox(height: 12),

                  // Save Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveDietTemplate,
                      icon: const Icon(Icons.save_rounded, color: Colors.black),
                      label: const Text(
                        'Save Diet Template',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMealSection({
    required String title,
    required TextEditingController foodController,
    required TextEditingController noteController,
    required TextEditingController kcalController,
    required IconData icon,
    required Color accentColor,
    required String foodHint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: foodController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              label: 'Food Items',
              hint: foodHint,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    label: 'Note / Instruction',
                    hint: 'e.g., Drink plenty of water',
                    accentColor: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: kcalController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration:
                      _inputDecoration(
                        label: 'Calories',
                        hint: '350',
                        accentColor: accentColor,
                      ).copyWith(
                        suffixText: 'kcal',
                        suffixStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required Color accentColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.15),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFF12141C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accentColor, width: 1.2),
      ),
    );
  }
}
