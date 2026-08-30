import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.parse(packageInfo.buildNumber);

      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('latest_version')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        int latestBuildNumber = data['latestBuildNumber'] ?? 0;
        String apkUrl = data['apkUrl'] ?? '';
        bool isForceUpdate = data['isForceUpdate'] ?? false;

        if (latestBuildNumber > currentBuildNumber && apkUrl.isNotEmpty) {
          if (context.mounted) {
            _showUpdateDialog(context, apkUrl, isForceUpdate);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check error: $e");
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String apkUrl,
    bool isForceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        double downloadProgress = 0.0;
        bool isDownloading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1D29),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.system_update_rounded, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text(
                    'New Update Available! 🚀',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'অ্যাপটির একটি নতুন সংস্করণ উপলব্ধ রয়েছে। দয়া করে সেরা পারফরম্যান্স পেতে এখনই আপডেট করুন।',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: downloadProgress / 100,
                      backgroundColor: Colors.white10,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Downloading: ${downloadProgress.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isForceUpdate && !isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Later',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                if (!isDownloading)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        isDownloading = true;
                      });

                      try {
                        OtaUpdate()
                            .execute(
                              apkUrl,
                              destinationFilename: 'app_update.apk',
                            )
                            .listen((OtaEvent event) {
                              if (event.status == OtaStatus.DOWNLOADING) {
                                setState(() {
                                  downloadProgress =
                                      double.tryParse(event.value ?? '0') ?? 0;
                                });
                              } else if (event.status == OtaStatus.INSTALLING) {
                                Navigator.pop(context);
                              }
                            });
                      } catch (e) {
                        setState(() {
                          isDownloading = false;
                        });
                      }
                    },
                    child: const Text(
                      'Update Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
