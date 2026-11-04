import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminQrScannerView extends StatefulWidget {
  const AdminQrScannerView({super.key});

  @override
  State<AdminQrScannerView> createState() => _AdminQrScannerViewState();
}

class _AdminQrScannerViewState extends State<AdminQrScannerView> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  Future<void> _handleQrDetection(String rawPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final String scannedGymId = rawPayload.trim();
      if (scannedGymId.isEmpty) {
        _resetProcessingWithDelay();
        return;
      }

      // 1. Query Firestore for member record by gymId (with fallback to UID)
      DocumentSnapshot? userDoc;
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('gymId', isEqualTo: scannedGymId)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        userDoc = querySnap.docs.first;
      } else {
        final directDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(scannedGymId)
            .get();

        if (directDoc.exists) {
          userDoc = directDoc;
        }
      }

      if (!mounted) return;

      if (userDoc == null || !userDoc.exists || userDoc.data() == null) {
        _showErrorSnackBar('Member with ID $scannedGymId not found!');
        _resetProcessingWithDelay();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String userId = userData['uid'] ?? userDoc.id;
      final String memberName = userData['name'] ?? 'Member';
      final String gymId = userData['gymId'] ?? 'N/A';
      final String planName = userData['planName'] ?? 'No Active Plan';
      final bool isSubscribed = userData['isSubscribed'] == true;
      final String status =
          userData['status']?.toString().toLowerCase() ?? 'approved';

      // 2. Check active membership status
      bool isActive = isSubscribed && status == 'approved';
      if (userData['expiryDate'] is Timestamp) {
        final DateTime expiryDate = (userData['expiryDate'] as Timestamp)
            .toDate();
        final DateTime today = DateTime.now();
        final diff = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        ).difference(DateTime(today.year, today.month, today.day)).inDays;

        if (diff < 0) {
          isActive = false;
        }
      }

      final now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final String formattedTime = DateFormat('hh:mm a').format(now);

      // Check for duplicate scan today
      final existingCheckin = await FirebaseFirestore.instance
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: formattedDate)
          .limit(1)
          .get();

      if (!mounted) return;

      if (existingCheckin.docs.isNotEmpty) {
        final checkinData = existingCheckin.docs.first.data();
        final recordedTime = checkinData['time']?.toString() ?? formattedTime;

        await _showAlreadyCheckedInModal(
          memberName: memberName,
          gymId: gymId,
          planName: planName,
          recordedTime: recordedTime,
        );
        return;
      }

      if (isActive) {
        // 3. Save attendance record to Firestore
        await FirebaseFirestore.instance.collection('attendance').add({
          'userId': userId,
          'memberName': memberName,
          'gymId': gymId,
          'timestamp': FieldValue.serverTimestamp(),
          'date': formattedDate,
          'time': formattedTime,
          'scannedBy': 'Trainer/Admin',
        });

        if (!mounted) return;
        await _showCheckInSuccessModal(
          memberName: memberName,
          gymId: gymId,
          planName: planName,
          time: formattedTime,
        );
      } else {
        if (!mounted) return;
        await _showInactiveMemberModal(
          memberName: memberName,
          gymId: gymId,
          planName: planName,
          userId: userId,
          formattedDate: formattedDate,
          formattedTime: formattedTime,
        );
      }
    } catch (e) {
      debugPrint("QR Scan processing error: $e");
      if (mounted) {
        _showErrorSnackBar("Error processing scan: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _resetProcessingWithDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAlreadyCheckedInModal({
    required String memberName,
    required String gymId,
    required String planName,
    required String recordedTime,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D29),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.amberAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.amberAccent,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Already Checked-In Today! ⏳',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              memberName,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gym ID: $gymId • $planName',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF12141C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.amberAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recorded Check-in at $recordedTime',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Understand / Scan Next',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCheckInSuccessModal({
    required String memberName,
    required String gymId,
    required String planName,
    required String time,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D29),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.cyanAccent,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check-in Successful! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              memberName,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gym ID: $gymId • $planName',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF12141C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Checked in at $time',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text(
                  'Scan Next Member',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInactiveMemberModal({
    required String memberName,
    required String gymId,
    required String planName,
    required String userId,
    required String formattedDate,
    required String formattedTime,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D29),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Membership Expired / Inactive ⚠️',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              memberName,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gym ID: $gymId • $planName',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseFirestore.instance
                          .collection('attendance')
                          .add({
                            'userId': userId,
                            'memberName': memberName,
                            'gymId': gymId,
                            'timestamp': FieldValue.serverTimestamp(),
                            'date': formattedDate,
                            'time': formattedTime,
                            'scannedBy': 'Trainer/Admin (Override)',
                          });
                    },
                    child: const Text(
                      'Allow Override',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D29),
        title: const Text(
          'Attendance QR Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.yellowAccent : Colors.grey,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessing) return;
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleQrDetection(rawValue);
                  break;
                }
              }
            },
          ),

          // Custom Dark Target Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyanAccent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D29).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.cyanAccent,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Align Spartan Digital Pass inside the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
