import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDietView extends StatefulWidget {
  const AddDietView({super.key});

  @override
  State<AddDietView> createState() => _AddDietViewState();
}

class _AddDietViewState extends State<AddDietView> {
  // ড্রপডাউন থেকে সিলেক্টেড মেম্বারের ডাটা রাখার ভেরিয়েবল
  String? _selectedUserEmail;
  String? _selectedUserName;

  // ব্রেকফাস্ট কন্ট্রোলারস
  final _breakfastController = TextEditingController();
  final _breakfastNoteController = TextEditingController();
  final _breakfastKcalController = TextEditingController();

  // লাঞ্চ কন্ট্রোলারস
  final _lunchController = TextEditingController();
  final _lunchNoteController = TextEditingController();
  final _lunchKcalController = TextEditingController();

  // ডিনার কন্ট্রোলারস
  final _dinnerController = TextEditingController();
  final _dinnerNoteController = TextEditingController();
  final _dinnerKcalController = TextEditingController();

  bool _isLoading = false;

  // 🔄 ইউজার সিলেক্ট করার পর তার আগের ডায়েট প্ল্যান ফায়ারস্টোর থেকে অটো-লোড করার মেথড
  Future<void> _fetchUserDietData(String email) async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('diet_charts')
          .doc(email)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // ব্রেকফাস্ট ডাটা লোড
        if (data['breakfast'] != null) {
          _breakfastController.text = data['breakfast']['food'] ?? '';
          _breakfastNoteController.text = data['breakfast']['note'] ?? '';
          _breakfastKcalController.text = data['breakfast']['kcal'] ?? '';
        }

        // লাঞ্চ ডাটা লোড
        if (data['lunch'] != null) {
          _lunchController.text = data['lunch']['food'] ?? '';
          _lunchNoteController.text = data['lunch']['note'] ?? '';
          _lunchKcalController.text = data['lunch']['kcal'] ?? '';
        }

        // ডিনার ডাটা লোড
        if (data['dinner'] != null) {
          _dinnerController.text = data['dinner']['food'] ?? '';
          _dinnerNoteController.text = data['dinner']['note'] ?? '';
          _dinnerKcalController.text = data['dinner']['kcal'] ?? '';
        }
      } else {
        // যদি ওই ইউজারের কোনো ডায়েট চার্ট না থাকে, তবে ফর্ম রিসেট হবে
        _clearFormFieldsOnly();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ডাটা লোড করতে সমস্যা হয়েছে: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🗑️ মেম্বারের সম্পূর্ণ ডায়েট চার্ট ডাটাবেজ থেকে মুছে ফেলার মেথড
  Future<void> _deleteEntireDietPlan() async {
    if (_selectedUserEmail == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        title: const Text(
          'ডায়েট প্ল্যান ডিলিট করুন 🚨',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'আপনি কি নিশ্চিত যে $_selectedUserName এর সম্পূর্ণ ডায়েট প্ল্যানটি ডিলিট করতে চান?',
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
                    .collection('diet_charts')
                    .doc(_selectedUserEmail)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$_selectedUserName এর ডায়েট চার্টটি ডিলিট করা হয়েছে। 🧹',
                      ),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  _clearFullForm();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ডিলিট করতে সমস্যা হয়েছে: $e'),
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

  void _clearFormFieldsOnly() {
    _breakfastController.clear();
    _breakfastNoteController.clear();
    _breakfastKcalController.clear();
    _lunchController.clear();
    _lunchNoteController.clear();
    _lunchKcalController.clear();
    _dinnerController.clear();
    _dinnerNoteController.clear();
    _dinnerKcalController.clear();
  }

  void _clearFullForm() {
    setState(() {
      _selectedUserEmail = null;
      _selectedUserName = null;
      _clearFormFieldsOnly();
    });
  }

  Future<void> _uploadDietChart() async {
    final email = _selectedUserEmail;
    final breakfast = _breakfastController.text.trim();
    final lunch = _lunchController.text.trim();
    final dinner = _dinnerController.text.trim();

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে একজন মেম্বার সিলেক্ট করুন! ⚠️'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (breakfast.isEmpty || lunch.isEmpty || dinner.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সবগুলো প্রধান খাবারের ঘর পূরণ করুন!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('diet_charts').doc(email).set(
        {
          'userEmail': email,
          'updatedAt': FieldValue.serverTimestamp(),
          'breakfast': {
            'food': breakfast,
            'note': _breakfastNoteController.text.trim(),
            'kcal': _breakfastKcalController.text.trim(),
          },
          'lunch': {
            'food': lunch,
            'note': _lunchNoteController.text.trim(),
            'kcal': _lunchKcalController.text.trim(),
          },
          'dinner': {
            'food': dinner,
            'note': _dinnerNoteController.text.trim(),
            'kcal': _dinnerKcalController.text.trim(),
          },
        },
        SetOptions(merge: true), // আগের ডাটা অক্ষুণ্ণ রেখে মার্জ করবে
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ডায়েট চার্ট সফলভাবে আপডেট হয়েছে! 🥗'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ভুল হয়েছে: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _breakfastNoteController.dispose();
    _breakfastKcalController.dispose();

    _lunchController.dispose();
    _lunchNoteController.dispose();
    _lunchKcalController.dispose();

    _dinnerController.dispose();
    _dinnerNoteController.dispose();
    _dinnerKcalController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Assign Diet Chart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_selectedUserEmail != null)
            IconButton(
              onPressed: _deleteEntireDietPlan,
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              tooltip: 'Delete this diet chart',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Member",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // 👥 মেম্বার ড্রপডাউন স্ট্রিম বিল্ডার
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator(
                          color: Colors.green,
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
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUserEmail,
                            hint: const Text(
                              'সিলেক্ট মেম্বার',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
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
                                // ইউজার সিলেক্ট করার সাথে সাথে তার আগের ডায়েট ডাটা রিয়েল-টাইমে লোড হবে
                                _fetchUserDietData(value);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 🍳 ব্রেকফাস্ট সেকশন
                  _buildMealSection(
                    title: 'Breakfast Menu',
                    foodController: _breakfastController,
                    noteController: _breakfastNoteController,
                    kcalController: _breakfastKcalController,
                    icon: Icons.wb_sunny_rounded,
                  ),

                  // 🍱 লাঞ্চ সেকশন
                  _buildMealSection(
                    title: 'Lunch Menu',
                    foodController: _lunchController,
                    noteController: _lunchNoteController,
                    kcalController: _lunchKcalController,
                    icon: Icons.wb_twilight_rounded,
                  ),

                  // 🍽️ ডিনার সেকশন
                  _buildMealSection(
                    title: 'Dinner Menu',
                    foodController: _dinnerController,
                    noteController: _dinnerNoteController,
                    kcalController: _dinnerKcalController,
                    icon: Icons.dark_mode_rounded,
                  ),

                  const SizedBox(height: 16),

                  // সাবমিট বাটন
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _uploadDietChart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update Diet Plan',
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

  Widget _buildMealSection({
    required String title,
    required TextEditingController foodController,
    required TextEditingController noteController,
    required TextEditingController kcalController,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
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
              hint: 'e.g. 2 Egg Whites, Oats',
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
                    hint: 'e.g. Eat before 9 AM',
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
                  decoration: _inputDecoration(label: 'Calories', hint: '350')
                      .copyWith(
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
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF12141C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 1.2),
      ),
    );
  }
}
