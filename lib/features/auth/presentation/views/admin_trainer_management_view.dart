// admin_trainer_management_view.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final _whatsappController = TextEditingController();
  final _facebookController = TextEditingController();

  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _addTrainer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    String downloadUrl = '';

    try {
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final String fileExtension = _selectedImage!.path
            .split('.')
            .last
            .toLowerCase();
        final String fileName =
            'trainers/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        final Reference storageRef = FirebaseStorage.instance.ref().child(
          fileName,
        );

        final UploadTask uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/$fileExtension'),
        );

        final TaskSnapshot snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          downloadUrl = await storageRef.getDownloadURL();
        } else {
          throw Exception('Image upload failed with state: ${snapshot.state}');
        }
      }

      await FirebaseFirestore.instance.collection('trainers').add({
        'name': _nameController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'experience': _experienceController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim().isEmpty
            ? _phoneController.text.trim()
            : _whatsappController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'photoUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _specialtyController.clear();
      _phoneController.clear();
      _experienceController.clear();
      _whatsappController.clear();
      _facebookController.clear();

      setState(() {
        _selectedImage = null;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trainer Profile Added Successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding trainer: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _deleteTrainer(String id, String? photoUrl) async {
    try {
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(photoUrl);
          await storageRef.delete();
        } catch (e) {
          debugPrint('Error deleting photo: $e');
        }
      }
      await FirebaseFirestore.instance.collection('trainers').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trainer Removed! ❌')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Trainer Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
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
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Photo Picker Section
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF1A1D29),
                            backgroundImage: _selectedImage != null
                                ? FileImage(File(_selectedImage!.path))
                                : null,
                            child: _selectedImage == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Colors.blueAccent,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to select trainer photo',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    _nameController,
                    'Trainer Full Name',
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _specialtyController,
                    'Specialty (e.g. Crossfit, Weight Loss)',
                    Icons.fitness_center_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _experienceController,
                    'Experience (e.g. 5 Years)',
                    Icons.workspace_premium_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _phoneController,
                    'Phone Number (e.g. 01712345678)',
                    Icons.phone_outlined,
                    keyBoardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _whatsappController,
                    'WhatsApp Number (e.g. 8801712345678)',
                    Icons.chat_rounded,
                    keyBoardType: TextInputType.phone,
                    isOptional: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _facebookController,
                    'Facebook Profile Link / Username',
                    Icons.link_rounded,
                    isOptional: true,
                  ),
                  const SizedBox(height: 20),

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
                      onPressed: _isUploading ? null : _addTrainer,
                      child: _isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No trainers added yet.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                final trainers = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trainers.length,
                  itemBuilder: (context, index) {
                    final data = trainers[index].data() as Map<String, dynamic>;
                    final docId = trainers[index].id;
                    final photoUrl = data['photoUrl']?.toString() ?? '';
                    final name = data['name']?.toString() ?? 'Trainer';
                    final specialty = data['specialty']?.toString() ?? '';
                    final exp = data['experience']?.toString() ?? '';
                    final phone = data['phone']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D29),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: Colors.blueAccent,
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "$specialty • $exp\nPhone: $phone",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteTrainer(docId, photoUrl),
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
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyBoardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.trim().isEmpty)) {
          return 'Required field';
        }
        return null;
      },
    );
  }
}
