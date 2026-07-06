import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDietView extends StatefulWidget {
  const AddDietView({super.key});

  @override
  State<AddDietView> createState() => _AddDietViewState();
}

class _AddDietViewState extends State<AddDietView> {
  final _emailController = TextEditingController();
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  bool _isLoading = false;

  Future<void> _uploadDietChart() async {
    final email = _emailController.text.trim();
    final breakfast = _breakfastController.text.trim();
    final lunch = _lunchController.text.trim();
    final dinner = _dinnerController.text.trim();

    if (email.isEmpty || breakfast.isEmpty || lunch.isEmpty || dinner.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সবগুলো ঘর পূরণ করুন!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ইমেইল অনুযায়ী নির্দিষ্ট ইউজারের ডায়েট ট্র্যাকিংয়ের জন্য ফায়ারস্টোরে সেভ
      await FirebaseFirestore.instance
          .collection('diet_charts')
          .doc(email)
          .set({
            'userEmail': email,
            'breakfast': breakfast,
            'lunch': lunch,
            'dinner': dinner,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ডায়েট চার্ট সফলভাবে আপডেট হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ভুল হয়েছে: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Diet Chart')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Member's Email Address",
                hintText: "user@email.com",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _breakfastController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Breakfast Menu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lunchController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Lunch Menu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dinnerController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Dinner Menu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadDietChart,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Diet Plan',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
