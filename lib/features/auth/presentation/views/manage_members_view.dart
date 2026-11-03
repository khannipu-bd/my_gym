import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageMembersView extends StatelessWidget {
  const ManageMembersView({super.key});

  // 🟢 Approve Pending Member with Membership Package Modal Sheet
  Future<void> _approveMember(
    BuildContext context,
    String docId,
    String userName, {
    String userEmail = '',
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int selectedDays = 30;
        String selectedPackageName = '1 Month Pack';
        int customDaysInput = 30;
        final customDaysController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final DateTime now = DateTime.now();
            final DateTime expiryDate = now.add(Duration(days: selectedDays));
            final String startDateStr = DateFormat('dd MMM yyyy').format(now);
            final String expiryDateStr = DateFormat(
              'dd MMM yyyy',
            ).format(expiryDate);

            return Padding(
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assign Membership Plan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$userName${userEmail.isNotEmpty ? ' • $userEmail' : ''}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      const Divider(color: Colors.white10, height: 20),
                      const Text(
                        'SELECT PACKAGE DURATION',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Package Options List
                      _buildPackageOptionTile(
                        title: '1 Month Pack (30 Days)',
                        days: 30,
                        packageName: '1 Month Pack',
                        isSelected:
                            selectedDays == 30 &&
                            selectedPackageName == '1 Month Pack',
                        onTap: () {
                          setModalState(() {
                            selectedDays = 30;
                            selectedPackageName = '1 Month Pack';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPackageOptionTile(
                        title: '3 Months Pack (90 Days)',
                        days: 90,
                        packageName: '3 Months Pack',
                        isSelected:
                            selectedDays == 90 &&
                            selectedPackageName == '3 Months Pack',
                        onTap: () {
                          setModalState(() {
                            selectedDays = 90;
                            selectedPackageName = '3 Months Pack';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPackageOptionTile(
                        title: '6 Months Pack (180 Days)',
                        days: 180,
                        packageName: '6 Months Pack',
                        isSelected:
                            selectedDays == 180 &&
                            selectedPackageName == '6 Months Pack',
                        onTap: () {
                          setModalState(() {
                            selectedDays = 180;
                            selectedPackageName = '6 Months Pack';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPackageOptionTile(
                        title: '1 Year Pack (365 Days)',
                        days: 365,
                        packageName: '1 Year Pack',
                        isSelected:
                            selectedDays == 365 &&
                            selectedPackageName == '1 Year Pack',
                        onTap: () {
                          setModalState(() {
                            selectedDays = 365;
                            selectedPackageName = '1 Year Pack';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPackageOptionTile(
                        title: 'Custom Days',
                        days: customDaysInput,
                        packageName: 'Custom Pack',
                        isSelected: selectedPackageName.startsWith('Custom'),
                        onTap: () {
                          setModalState(() {
                            selectedPackageName =
                                'Custom ($customDaysInput Days)';
                            selectedDays = customDaysInput;
                          });
                        },
                      ),

                      if (selectedPackageName.startsWith('Custom')) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: customDaysController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter number of days (e.g. 15, 45, 60)',
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF12141C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.edit_calendar,
                              color: Colors.blueAccent,
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val) ?? 30;
                            setModalState(() {
                              customDaysInput = parsed.clamp(1, 3650);
                              selectedDays = customDaysInput;
                              selectedPackageName =
                                  'Custom ($customDaysInput Days)';
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Validity Preview Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12141C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              color: Colors.greenAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Validity Preview ($selectedDays Days)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Start: $startDateStr • Expires: $expiryDateStr',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  final DateTime now = DateTime.now();
                                  final DateTime calculatedExpiry = now.add(
                                    Duration(days: selectedDays),
                                  );

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(docId)
                                      .update({
                                        'status': 'approved',
                                        'isSubscribed': true,
                                        'planName': selectedPackageName,
                                        'membershipPackage':
                                            selectedPackageName,
                                        'membershipDurationDays': selectedDays,
                                        'membershipStartDate':
                                            FieldValue.serverTimestamp(),
                                        'membershipExpiryDate':
                                            Timestamp.fromDate(
                                              calculatedExpiry,
                                            ),
                                        'expiryDate': Timestamp.fromDate(
                                          calculatedExpiry,
                                        ),
                                        'approvedAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Member approved successfully with $selectedPackageName! 🟢',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to approve member: $e',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                'Confirm & Activate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPackageOptionTile({
    required String title,
    required int days,
    required String packageName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : const Color(0xFF12141C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF10B981) : Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 🔴 Reject Pending Member
  Future<void> _rejectMember(
    BuildContext context,
    String docId,
    String userName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Decline Request ⚠️',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to decline the membership request for $userName?',
          style: const TextStyle(color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'status': 'rejected',
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Membership request for $userName was declined.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to decline request: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // মেম্বার লক/আনব্লক (Block/Unblock) করার ফাংশন
  Future<void> _toggleBlockUser(
    BuildContext context,
    String docId,
    String userName,
    bool currentStatus,
  ) async {
    final actionText = currentStatus ? 'Unblock' : 'Block';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm $actionText ⚠️',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'আপনি কি নিশ্চিতভাবেই $userName-এর অ্যাকাউন্টটি $actionText করতে চান?',
          style: const TextStyle(color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.green : Colors.redAccent,
            ),
            child: Text(
              actionText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'isBlocked': !currentStatus,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$userName-কে সফলভাবে ${currentStatus ? 'আনব্লক' : 'ব্লক'} করা হয়েছে! 🔒',
              ),
              backgroundColor: currentStatus ? Colors.green : Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('অ্যাকশনটি সম্পন্ন করা যায়নি: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // মেম্বার স্থায়ীভাবে মুছে ফেলার (Delete User) ফাংশন
  Future<void> _deleteUser(
    BuildContext context,
    String userId,
    String userName,
    String userEmail,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete User ⚠️',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this member? This action cannot be undone.',
          style: TextStyle(color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName has been deleted.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Gym Members & Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Separate pending requests from active/approved members
          final pendingDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();

          final approvedDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] != 'pending' && data['status'] != 'rejected';
          }).toList();

          final totalUsers = approvedDocs.length;
          final pendingCount = pendingDocs.length;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STATS BANNER
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D29),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.people_alt_rounded,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$totalUsers',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Active Members',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D29),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: pendingCount > 0
                                  ? Colors.amberAccent.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add_rounded,
                                color: pendingCount > 0
                                    ? Colors.amberAccent
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$pendingCount',
                                style: TextStyle(
                                  color: pendingCount > 0
                                      ? Colors.amberAccent
                                      : Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Pending Requests',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. PENDING REQUESTS SECTION
                if (pendingDocs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.amberAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PENDING MEMBERSHIP REQUESTS',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pendingDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          pendingDocs[index].data() as Map<String, dynamic>;
                      final docId = pendingDocs[index].id;
                      final name = data['name']?.toString() ?? 'Unknown User';
                      final email = data['email']?.toString() ?? '';
                      final phone = data['phone']?.toString() ?? 'N/A';
                      final gymId = data['gymId']?.toString() ?? 'N/A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D29),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    gymId,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_android_rounded,
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Phone: $phone',
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _rejectMember(context, docId, name),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveMember(
                                      context,
                                      docId,
                                      name,
                                      userEmail: email,
                                    ),
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. APPROVED MEMBERS SECTION
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'REGISTERED MEMBERS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                if (approvedDocs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'কোনো সক্রিয় মেম্বার খুঁজে পাওয়া যায়নি! 👤',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: approvedDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          approvedDocs[index].data() as Map<String, dynamic>;
                      final docId = approvedDocs[index].id;
                      final name = data['name']?.toString() ?? 'Unknown User';
                      final email = data['email']?.toString() ?? docId;
                      final gymId = data['gymId']?.toString() ?? 'N/A';
                      String joinDateText = 'N/A';

                      if (data['joiningDate'] is Timestamp) {
                        final Timestamp joinTimestamp =
                            data['joiningDate'] as Timestamp;
                        final DateTime joinDate = joinTimestamp.toDate();
                        joinDateText = DateFormat(
                          'dd MMM yyyy',
                        ).format(joinDate);
                      }

                      final height = data['height']?.toString() ?? 'N/A';
                      final weight = data['weight']?.toString() ?? 'N/A';
                      final bloodGroup = data['blood']?.toString() ?? 'N/A';
                      final emergencyContact =
                          data['phone']?.toString() ?? 'N/A';
                      final age = data['age']?.toString() ?? 'N/A';
                      final gender = data['gender']?.toString() ?? 'N/A';
                      final goal = data['goal']?.toString() ?? 'N/A';
                      final bool isBlocked = data['isBlocked'] == true;
                      final String planName =
                          data['planName']?.toString() ?? 'No Plan';
                      bool isActive = data['isSubscribed'] == true;
                      String daysLeftText = "Expired";

                      if (data['expiryDate'] is Timestamp) {
                        final Timestamp expiryTimestamp =
                            data['expiryDate'] as Timestamp;
                        final DateTime expiryDate = expiryTimestamp.toDate();
                        final DateTime today = DateTime.now();

                        final difference =
                            DateTime(
                                  expiryDate.year,
                                  expiryDate.month,
                                  expiryDate.day,
                                )
                                .difference(
                                  DateTime(today.year, today.month, today.day),
                                )
                                .inDays;

                        if (difference > 0 && isActive) {
                          daysLeftText = "$difference Days Remaining";
                        } else if (difference == 0 && isActive) {
                          daysLeftText = "Expires Today! ⚠️";
                        } else {
                          daysLeftText = "Expired / Inactive";
                          isActive = false;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D29),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isBlocked
                                ? Colors.redAccent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ExpansionTile(
                          backgroundColor: const Color(0xFF1A1D29),
                          collapsedBackgroundColor: const Color(0xFF1A1D29),
                          shape: const Border(),
                          iconColor: Colors.blueAccent,
                          collapsedIconColor: Colors.grey,
                          leading: CircleAvatar(
                            backgroundColor: isBlocked
                                ? Colors.redAccent.withValues(alpha: 0.1)
                                : Colors.blueAccent.withValues(alpha: 0.1),
                            child: Icon(
                              isBlocked
                                  ? Icons.lock_rounded
                                  : Icons.person_rounded,
                              color: isBlocked
                                  ? Colors.redAccent
                                  : Colors.blueAccent,
                            ),
                          ),
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  gymId,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isBlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LOCKED',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Divider(
                                    color: Colors.white10,
                                    height: 1,
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoTag('Age', age),
                                      _buildInfoTag('Gender', gender),
                                      _buildInfoTag('Goal', goal),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoTag('Height', height),
                                      _buildInfoTag('Weight', weight),
                                      _buildInfoTag('Blood', bloodGroup),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.02,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isActive
                                            ? Colors.greenAccent.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.redAccent.withValues(
                                                alpha: 0.2,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.lock_clock_outlined
                                                  : Icons.timer_off_outlined,
                                              color: isActive
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Plan: $planName',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    daysLeftText,
                                                    style: TextStyle(
                                                      color: isActive
                                                          ? Colors.greenAccent
                                                          : Colors.redAccent,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(
                                          color: Colors.white10,
                                          height: 16,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              color: Colors.blueAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Joined: $joinDateText',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.emergency_share_rounded,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Phone / Emergency: $emergencyContact',
                                          style: const TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _toggleBlockUser(
                                        context,
                                        docId,
                                        name,
                                        isBlocked,
                                      ),
                                      icon: Icon(
                                        isBlocked
                                            ? Icons.lock_open_rounded
                                            : Icons.lock_person_rounded,
                                        color: isBlocked
                                            ? Colors.green
                                            : Colors.redAccent,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isBlocked
                                            ? 'Unblock Member Account'
                                            : 'Block Member Account',
                                        style: TextStyle(
                                          color: isBlocked
                                              ? Colors.green
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: isBlocked
                                              ? Colors.green
                                              : Colors.redAccent,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _deleteUser(
                                        context,
                                        docId,
                                        name,
                                        email,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Delete User',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTag(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
