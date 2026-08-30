// admin_trainer_management_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminTrainerManagementView extends StatefulWidget {
  const AdminTrainerManagementView({super.key});

  @override
  State<AdminTrainerManagementView> createState() =>
      _AdminTrainerManagementViewState();
}

class _AdminTrainerManagementViewState
    extends State<AdminTrainerManagementView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();

  void _addTrainer() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('trainers').add({
        'name': _nameController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'phone': _phoneController.text.trim(),
        'experience': _experienceController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _specialtyController.clear();
      _phoneController.clear();
      _experienceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trainer Added Successfully! 🎉')),
      );
    }
  }

  void _deleteTrainer(String id) async {
    await FirebaseFirestore.instance.collection('trainers').doc(id).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trainer Removed! ❌')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Trainer Profile Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Trainer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    _nameController,
                    'Trainer Name',
                    Icons.person,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _specialtyController,
                    'Specialty (e.g., Weight Loss, Yoga)',
                    Icons.fitness_center,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _experienceController,
                    'Experience (e.g., 3 Years)',
                    Icons.workspace_premium,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _phoneController,
                    'Contact/Phone Number',
                    Icons.phone,
                    keyBoardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addTrainer,
                      child: const Text(
                        'Save Trainer Profile',
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
            const SizedBox(height: 30),
            const Text(
              'Current Trainers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trainers')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.purpleAccent,
                    ),
                  );
                final trainers = snapshot.data!.docs;
                if (trainers.isEmpty) {
                  return const Text(
                    'No trainers added yet.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trainers.length,
                  itemBuilder: (context, index) {
                    final data = trainers[index].data() as Map<String, dynamic>;
                    final docId = trainers[index].id;
                    return Card(
                      color: const Color(0xFF1A1D29),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${data['specialty']} (${data['experience']})\nPhone: ${data['phone']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteTrainer(docId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyBoardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyBoardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Required field' : null,
    );
  }
}
