// user_contact_trainer_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserContactTrainerView extends StatelessWidget {
  const UserContactTrainerView({super.key});

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid WhatsApp number provided.')),
        );
      }
      return;
    }

    String number = sanitized;
    if (number.startsWith('01')) {
      number = '88$number';
    }

    final url =
        "https://wa.me/$number?text=${Uri.encodeComponent('Hello Trainer, I would like to consult with you.')}";
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching WhatsApp: $e')));
      }
    }
  }

  Future<void> _launchFacebook(BuildContext context, String fbInput) async {
    if (fbInput.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Facebook profile link available.')),
        );
      }
      return;
    }

    String fbUrl = fbInput.trim();
    if (!fbUrl.startsWith('http://') && !fbUrl.startsWith('https://')) {
      fbUrl = 'https://facebook.com/$fbUrl';
    }

    final Uri uri = Uri.parse(fbUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Facebook link.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
    }
  }

  Future<void> _launchPhoneCall(BuildContext context, String phone) async {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available.')),
        );
      }
      return;
    }

    final Uri uri = Uri.parse("tel:$sanitized");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not initiate call.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching call: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Contact Expert Trainers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(
              child: Text(
                'No trainers available right now.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final trainers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trainers.length,
            itemBuilder: (context, index) {
              final data = trainers[index].data() as Map<String, dynamic>;
              final String name = data['name']?.toString() ?? 'Expert Trainer';
              final String specialty =
                  data['specialty']?.toString() ?? 'Fitness Coach';
              final String experience = data['experience']?.toString() ?? 'N/A';
              final String phone = data['phone']?.toString() ?? '';
              final String whatsapp = data['whatsapp']?.toString() ?? phone;
              final String facebook = data['facebook']?.toString() ?? '';
              final String photoUrl = data['photoUrl']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D29),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.15,
                          ),
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: Colors.blueAccent,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                specialty,
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Experience: $experience",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    // Quick Action Buttons Row
                    Row(
                      children: [
                        // WhatsApp Button
                        Expanded(
                          child: _buildActionButton(
                            label: 'WhatsApp',
                            icon: Icons.chat_rounded,
                            color: const Color(0xFF25D366),
                            onTap: () => _launchWhatsApp(context, whatsapp),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Facebook Button
                        Expanded(
                          child: _buildActionButton(
                            label: 'Facebook',
                            icon: Icons.facebook_rounded,
                            color: const Color(0xFF1877F2),
                            onTap: () => _launchFacebook(context, facebook),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Call Button
                        Expanded(
                          child: _buildActionButton(
                            label: 'Call',
                            icon: Icons.phone_rounded,
                            color: Colors.blueAccent,
                            onTap: () => _launchPhoneCall(context, phone),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
