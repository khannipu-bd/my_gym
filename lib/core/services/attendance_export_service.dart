import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceExportService {
  /// Export PDF report for attendance records on a specific date (defaults to today)
  static Future<void> exportAttendancePdf({String? targetDate}) async {
    final String dateStr =
        targetDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Query Firestore attendance records for date
    final querySnap = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: dateStr)
        .get();

    final docs = querySnap.docs;

    // Sort records in memory by timestamp descending
    docs.sort((a, b) {
      final tA = a.data()['timestamp'] as Timestamp?;
      final tB = b.data()['timestamp'] as Timestamp?;
      if (tA == null || tB == null) return 0;
      return tB.compareTo(tA);
    });

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SPARTAN GYM',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Daily Attendance Register Report',
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: $dateStr',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Present: ${docs.length}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 14),

              // Attendance Table
              if (docs.isEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 40),
                    child: pw.Text(
                      'No attendance records found for $dateStr.',
                      style: const pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.8,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                  ),
                  cellHeight: 26,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: [
                    'SL',
                    'Member Name',
                    'Gym ID',
                    'Check-in Time',
                    'Status',
                  ],
                  data: List<List<String>>.generate(docs.length, (index) {
                    final data = docs[index].data();
                    final memberName = data['memberName'] ?? 'Member';
                    final gymId = data['gymId'] ?? 'N/A';
                    final time = data['time'] ?? 'N/A';
                    return [
                      '${index + 1}',
                      memberName.toString(),
                      gymId.toString(),
                      time.toString(),
                      'Verified',
                    ];
                  }),
                ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Spartan Gym Management System',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Share / Print PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'SpartanGym_Attendance_$dateStr.pdf',
    );
  }

  /// Export Monthly Attendance Breakdown PDF report
  static Future<void> exportMonthlyAttendancePdf({
    required int year,
    required int month,
  }) async {
    final DateTime targetMonth = DateTime(year, month);
    final String monthYearStr = DateFormat('MMMM yyyy').format(targetMonth);
    final String yearMonthPrefix = DateFormat('yyyy-MM').format(targetMonth);
    final int totalDaysInMonth = DateTime(year, month + 1, 0).day;

    final now = DateTime.now();
    final int daysSoFar = (year == now.year && month == now.month)
        ? now.day
        : totalDaysInMonth;

    // 1. Query all attendance documents for target month
    final attendanceSnap = await FirebaseFirestore.instance
        .collection('attendance')
        .get();

    final monthDocs = attendanceSnap.docs.where((doc) {
      final data = doc.data();
      final date = data['date']?.toString() ?? '';
      return date.startsWith(yearMonthPrefix);
    }).toList();

    // 2. Fetch all members from `users` collection
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .get();

    final Map<String, Map<String, dynamic>> memberStats = {};

    for (var userDoc in usersSnap.docs) {
      final userData = userDoc.data();
      final status = userData['status']?.toString().toLowerCase() ?? 'approved';
      if (status == 'pending' || status == 'rejected') continue;

      final uid = userData['uid'] ?? userDoc.id;
      final name = userData['name'] ?? 'Member';
      final gymId = userData['gymId'] ?? 'N/A';

      memberStats[uid] = {'name': name, 'gymId': gymId, 'presentDays': <int>{}};
    }

    // Populate attendance records
    for (var doc in monthDocs) {
      final data = doc.data();
      final uid = data['userId']?.toString() ?? '';
      final dateStr = data['date']?.toString() ?? '';
      if (uid.isEmpty || !dateStr.startsWith(yearMonthPrefix)) {
        continue;
      }

      try {
        final day = DateTime.parse(dateStr).day;
        if (memberStats.containsKey(uid)) {
          (memberStats[uid]!['presentDays'] as Set<int>).add(day);
        } else {
          memberStats[uid] = {
            'name': data['memberName'] ?? 'Member',
            'gymId': data['gymId'] ?? 'N/A',
            'presentDays': <int>{day},
          };
        }
      } catch (_) {}
    }

    // Convert to sorted list by total days present descending
    final memberList = memberStats.values.toList();
    memberList.sort((a, b) {
      final pA = (a['presentDays'] as Set<int>).length;
      final pB = (b['presentDays'] as Set<int>).length;
      return pB.compareTo(pA);
    });

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SPARTAN GYM',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Monthly Member Attendance Breakdown ($monthYearStr)',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Members: ${memberList.length}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Days in Month: $totalDaysInMonth',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 14),

              if (memberList.isEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 40),
                    child: pw.Text(
                      'No member attendance data found for $monthYearStr.',
                      style: const pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.8,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                  ),
                  cellHeight: 26,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: [
                    'SL',
                    'Gym ID',
                    'Member Name',
                    'Days Present',
                    'Consistency %',
                  ],
                  data: List<List<String>>.generate(memberList.length, (index) {
                    final member = memberList[index];
                    final presentCount =
                        (member['presentDays'] as Set<int>).length;
                    final pct = daysSoFar > 0
                        ? ((presentCount / daysSoFar) * 100).round()
                        : 0;

                    return [
                      '${index + 1}',
                      member['gymId'].toString(),
                      member['name'].toString(),
                      '$presentCount / $totalDaysInMonth Days',
                      '$pct%',
                    ];
                  }),
                ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Spartan Gym Management System',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'SpartanGym_Monthly_Attendance_${year}_$month.pdf',
    );
  }
}
