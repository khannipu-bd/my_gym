import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // ১. বর্তমান অ্যাপের বিল্ড নাম্বার নেওয়া
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // ২. ফায়ারবেস থেকে নতুন আপডেট তথ্য আনা
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('latest_version')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        int latestBuildNumber = (data['latestBuildNumber'] is int)
            ? data['latestBuildNumber']
            : int.tryParse(data['latestBuildNumber']?.toString() ?? '0') ?? 0;

        String rawApkUrl = data['apkUrl']?.toString() ?? '';
        bool isForceUpdate = data['isForceUpdate'] == true;

        debugPrint("📱 Installed Build: $currentBuildNumber");
        debugPrint("🔥 Firebase Build: $latestBuildNumber");

        // ৩. ভার্সন চেক
        if (latestBuildNumber > currentBuildNumber && rawApkUrl.isNotEmpty) {
          String directUrl = _getDirectDownloadLink(rawApkUrl);

          if (context.mounted) {
            _showUpdateDialog(context, directUrl, isForceUpdate);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Update check failed: $e");
    }
  }

  // গুগল ড্রাইভ এবং ড্রপবক্সের জন্য ডাইরেক্ট ডাউনলোড লিংক হ্যান্ডেল করা
  static String _getDirectDownloadLink(String url) {
    // 📦 Dropbox Link Fix: dl=0 থাকলে তা অটোমেটিক dl=1 করে দেবে
    if (url.contains("dropbox.com")) {
      return url.replaceAll("dl=0", "dl=1");
    }

    // 📁 Google Drive Link Fix
    if (url.contains("drive.google.com")) {
      RegExp regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      Match? match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        String fileId = match.group(1)!;
        return "https://drive.google.com/uc?export=download&id=$fileId&confirm=t";
      }
    }

    return url;
  }

  // আপডেট ডায়ালগ পপ-আপ
  static void _showUpdateDialog(
    BuildContext context,
    String apkUrl,
    bool isForce,
  ) {
    ValueNotifier<String> progressNotifier = ValueNotifier<String>("0%");
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // ব্যাক বাটন বা বাইরে ক্লিকে পপ-আপ যাওয়া বন্ধ
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // পপ-আপ নামানো প্রতিরোধ করবে
          child: StatefulBuilder(
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
                      'Update Available! 🚀',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isForce
                          ? 'A mandatory update is available. Please update to continue.'
                          : 'A new version of the app is available. Update now to get the latest features.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: 20),
                      ValueListenableBuilder<String>(
                        valueListenable: progressNotifier,
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LinearProgressIndicator(
                                color: Colors.blueAccent,
                                backgroundColor: Colors.white10,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Status: $value",
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (!isForce && !isDownloading)
                    TextButton(
                      child: const Text(
                        'Later',
                        style: TextStyle(color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  if (!isDownloading)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        setState(() {
                          isDownloading = true;
                        });
                        _startOtaUpdate(apkUrl, progressNotifier);
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ফাইল ডাউনলোড ও ইনস্টলেশন
  static void _startOtaUpdate(
    String url,
    ValueNotifier<String> progressNotifier,
  ) {
    try {
      OtaUpdate()
          .execute(url, destinationFilename: 'app-release.apk')
          .listen(
            (OtaEvent event) {
              if (event.status == OtaStatus.DOWNLOADING) {
                progressNotifier.value = "Downloading ${event.value}%";
              } else if (event.status == OtaStatus.INSTALLING) {
                progressNotifier.value = "Installing APK...";
              } else if (event.status ==
                  OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
                progressNotifier.value = "Permission denied!";
              } else if (event.status == OtaStatus.INTERNAL_ERROR) {
                progressNotifier.value = "Download failed!";
              } else if (event.status == OtaStatus.CHECKSUM_ERROR) {
                progressNotifier.value = "Checksum error!";
              }
            },
            onError: (error) {
              debugPrint("OTA Error: $error");
              progressNotifier.value = "Error: $error";
            },
          );
    } catch (e) {
      debugPrint("Failed to start OTA update: $e");
    }
  }
}
