// add member view
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // 👈 এটি অবশ্যই লাগবে সেকেন্ডারি অ্যাপের জন্য
import 'package:flutter/material.dart';

class AddMemberView extends StatefulWidget {
  const AddMemberView({super.key});

  @override
  State<AddMemberView> createState() => _AddMemberViewState();
}

class _AddMemberViewState extends State<AddMemberView> {
  final _formKey = GlobalKey<FormState>();

  // ইনপুট ফিল্ডগুলোর কন্ট্রোলার
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ৪টি অপশনের ডিউরেশন লিস্ট এবং ডিফল্ট সিলেক্টেড ভ্যালু
  String _selectedDuration = '1 Month';
  final List<String> _durationOptions = [
    '1 Month',
    '3 Months',
    '6 Months',
    '1 Year',
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;

  int _getDaysFromDuration(String duration) {
    switch (duration) {
      case '1 Month':
        return 30;
      case '3 Months':
        return 90;
      case '6 Months':
        return 180;
      case '1 Year':
        return 365;
      default:
        return 30;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // মেম্বার অ্যাড করার মূল ফাংশন
  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final int days = _getDaysFromDuration(_selectedDuration);
      final DateTime today = DateTime.now();
      final DateTime expiryDate = today.add(Duration(days: days));

      // 🧠 ট্রিক: সেকেন্ডারি ফায়ারবেস অ্যাপ তৈরি করা যাতে এডমিন লগআউট না হয় এবং সঠিক UID ফায়ারস্টোরে যায়
      String appName = 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}';
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // ১. সেকেন্ডারি ইনস্ট্যান্স দিয়ে Firebase Auth-এ মেম্বার তৈরি করা
      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String? newUserId = userCredential.user?.uid;

      if (newUserId != null) {
        // ২. রিয়েল UID ব্যবহার করে ফায়ারস্টোরে 'users' কালেকশনের আন্ডারে নতুন ডকুমেন্ট তৈরি
        // নিশ্চিত করুন আপনার ইউজার হোম স্ক্রিন এই ফিল্ডগুলোই রিড করছে (uid, planName, expiryDate, isSubscribed)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUserId)
            .set({
              'uid': newUserId,
              'name': name,
              'email': email,
              'planName': '$_selectedDuration Pack',
              'isSubscribed': true,
              'createdAt': FieldValue.serverTimestamp(),
              'expiryDate': Timestamp.fromDate(expiryDate),
            });

        // ক্রিয়েট করা সাময়িক অ্যাপটি ডিলিট করে মেমোরি ক্লিন করা
        await secondaryApp.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member added to Auth & Database perfectly! 🔥'),
              backgroundColor: Colors.green,
            ),
          );

          // ফর্ম ক্লিয়ার করে দেওয়া
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          setState(() {
            _selectedDuration = '1 Month';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Auth Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Add New Member',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Member Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_rounded,
                      hint: 'John Doe',
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_rounded,
                      hint: 'johndoe@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_rounded,
                          color: Colors.purpleAccent,
                          size: 22,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A1D29),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.purpleAccent,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      'Membership Package Details',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Select Duration',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.6,
                          ),
                      itemCount: _durationOptions.length,
                      itemBuilder: (context, index) {
                        final option = _durationOptions[index];
                        final isSelected = _selectedDuration == option;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDuration = option;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.purpleAccent.withOpacity(0.15)
                                  : const Color(0xFF1A1D29),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.purpleAccent
                                    : Colors.white.withOpacity(0.05),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.purpleAccent
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _addMember,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Save & Activate Member',
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
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.purpleAccent, size: 22),
        filled: true,
        fillColor: const Color(0xFF1A1D29),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
    );
  }
}
