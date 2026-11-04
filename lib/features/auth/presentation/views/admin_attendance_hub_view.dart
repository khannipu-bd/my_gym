import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/attendance_export_service.dart';

class AdminAttendanceHubView extends StatefulWidget {
  const AdminAttendanceHubView({super.key});

  @override
  State<AdminAttendanceHubView> createState() => _AdminAttendanceHubViewState();
}

class _AdminAttendanceHubViewState extends State<AdminAttendanceHubView> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1D29),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1A1D29),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showMonthlyBreakdownModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthlyBreakdownModal(
        initialYear: _selectedDate.year,
        initialMonth: _selectedDate.month,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D29),
        title: const Text(
          'Attendance Hub & Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Export',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ],
              ),
            ),
            color: const Color(0xFF1E2230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'daily') {
                final formattedDate = DateFormat(
                  'yyyy-MM-dd',
                ).format(_selectedDate);
                await AttendanceExportService.exportAttendancePdf(
                  targetDate: formattedDate,
                );
              } else if (value == 'monthly') {
                await AttendanceExportService.exportMonthlyAttendancePdf(
                  year: _selectedDate.year,
                  month: _selectedDate.month,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'daily',
                child: Row(
                  children: [
                    const Icon(
                      Icons.today_rounded,
                      color: Colors.cyanAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Daily Report (${DateFormat('dd MMM').format(_selectedDate)})',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF00E676),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Monthly Report (${DateFormat('MMMM yyyy').format(_selectedDate)})',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Date-wise Calendar Explorer Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1A1D29),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.cyanAccent,
                          size: 28,
                        ),
                        onPressed: () => _changeDate(-1),
                      ),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12141C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.cyanAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'EEE, MMM dd, yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.cyanAccent,
                          size: 28,
                        ),
                        onPressed: () => _changeDate(1),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Attendance Stream for Selected Date
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('date', isEqualTo: selectedDateStr)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                  sortedDocs.sort((a, b) {
                    final tA =
                        (a.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    final tB =
                        (b.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    if (tA == null || tB == null) return 0;
                    return tB.compareTo(tA);
                  });

                  return Column(
                    children: [
                      // Summary Count Badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D29),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "Check-ins on ${DateFormat('MMM dd').format(_selectedDate)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${sortedDocs.length} Members',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Check-in Members List
                      Expanded(
                        child: sortedDocs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.event_busy_rounded,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No check-ins recorded for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}.',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: sortedDocs.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      sortedDocs[index].data()
                                          as Map<String, dynamic>;
                                  final name = data['memberName'] ?? 'Member';
                                  final gymId = data['gymId'] ?? 'N/A';
                                  final time = data['time'] ?? 'N/A';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1D29),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent
                                                .withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.greenAccent,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
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
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Gym ID: $gymId',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            time,
                                            style: const TextStyle(
                                              color: Colors.cyanAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Bottom Action Section - Monthly Breakdown Trigger
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _showMonthlyBreakdownModal(context),
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text(
                    'View Monthly Member Breakdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBreakdownModal extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthlyBreakdownModal({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthlyBreakdownModal> createState() => _MonthlyBreakdownModalState();
}

class _MonthlyBreakdownModalState extends State<_MonthlyBreakdownModal> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(widget.initialYear, widget.initialMonth);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String yearMonthPrefix = DateFormat('yyyy-MM').format(_selectedMonth);
    final String monthYearStr = DateFormat('MMMM yyyy').format(_selectedMonth);
    final int totalDaysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final now = DateTime.now();
    final int daysSoFar =
        (_selectedMonth.year == now.year && _selectedMonth.month == now.month)
        ? now.day
        : totalDaysInMonth;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D29),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header & Close Button
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: Color(0xFF00E676),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Monthly Attendance Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Month Switcher Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF12141C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.greenAccent,
                  ),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthYearStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.greenAccent,
                  ),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Members Breakdown Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .snapshots(),
              builder: (context, attendanceSnap) {
                if (attendanceSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                final attendanceDocs = attendanceSnap.data?.docs ?? [];
                final monthAttendance = attendanceDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = data['date']?.toString() ?? '';
                  return date.startsWith(yearMonthPrefix);
                }).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                      );
                    }

                    final userDocs = userSnap.data?.docs ?? [];
                    final Map<String, Map<String, dynamic>> memberStats = {};

                    for (var uDoc in userDocs) {
                      final uData = uDoc.data() as Map<String, dynamic>;
                      final status =
                          uData['status']?.toString().toLowerCase() ??
                          'approved';
                      if (status == 'pending' || status == 'rejected') continue;

                      final uid = uData['uid'] ?? uDoc.id;
                      final name = uData['name'] ?? 'Member';
                      final gymId = uData['gymId'] ?? 'N/A';

                      memberStats[uid] = {
                        'name': name,
                        'gymId': gymId,
                        'presentDays': <int>{},
                      };
                    }

                    for (var aDoc in monthAttendance) {
                      final aData = aDoc.data() as Map<String, dynamic>;
                      final uid = aData['userId']?.toString() ?? '';
                      final dateStr = aData['date']?.toString() ?? '';
                      if (uid.isEmpty || !dateStr.startsWith(yearMonthPrefix)) {
                        continue;
                      }

                      try {
                        final day = DateTime.parse(dateStr).day;
                        if (memberStats.containsKey(uid)) {
                          (memberStats[uid]!['presentDays'] as Set<int>).add(
                            day,
                          );
                        } else {
                          memberStats[uid] = {
                            'name': aData['memberName'] ?? 'Member',
                            'gymId': aData['gymId'] ?? 'N/A',
                            'presentDays': <int>{day},
                          };
                        }
                      } catch (_) {}
                    }

                    final memberList = memberStats.values.toList();
                    memberList.sort((a, b) {
                      final pA = (a['presentDays'] as Set<int>).length;
                      final pB = (b['presentDays'] as Set<int>).length;
                      return pB.compareTo(pA);
                    });

                    if (memberList.isEmpty) {
                      return const Center(
                        child: Text(
                          'No active members found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: memberList.length,
                      itemBuilder: (context, index) {
                        final member = memberList[index];
                        final name = member['name'];
                        final gymId = member['gymId'];
                        final presentCount =
                            (member['presentDays'] as Set<int>).length;
                        final pct = daysSoFar > 0
                            ? ((presentCount / daysSoFar) * 100).round()
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12141C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.greenAccent.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'ID: $gymId',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$presentCount / $totalDaysInMonth Days',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$pct% Consistency',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
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
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Export Monthly PDF Report Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                AttendanceExportService.exportMonthlyAttendancePdf(
                  year: _selectedMonth.year,
                  month: _selectedMonth.month,
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                'Export Monthly PDF ($monthYearStr)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
