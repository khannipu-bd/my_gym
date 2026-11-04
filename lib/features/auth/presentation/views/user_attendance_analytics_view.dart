import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserAttendanceAnalyticsView extends StatefulWidget {
  const UserAttendanceAnalyticsView({super.key});

  @override
  State<UserAttendanceAnalyticsView> createState() =>
      _UserAttendanceAnalyticsViewState();
}

class _UserAttendanceAnalyticsViewState
    extends State<UserAttendanceAnalyticsView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

    final int totalDaysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final int daysSoFar =
        (_selectedMonth.year == now.year && _selectedMonth.month == now.month)
        ? now.day
        : totalDaysInMonth;

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D29),
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Month Switcher Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D29),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Stream & Analytics Data
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('userId', isEqualTo: currentUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final yearMonthStr = DateFormat(
                    'yyyy-MM',
                  ).format(_selectedMonth);

                  final monthDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = data['date']?.toString() ?? '';
                    return date.startsWith(yearMonthStr);
                  }).toList();

                  final Set<int> presentDays = monthDocs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final date = data['date']?.toString() ?? '';
                        try {
                          return DateTime.parse(date).day;
                        } catch (_) {
                          return 0;
                        }
                      })
                      .where((day) => day > 0)
                      .toSet();

                  final int presentCount = presentDays.length;
                  final int consistencyPct = daysSoFar > 0
                      ? ((presentCount / daysSoFar) * 100).round()
                      : 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Days Present',
                              value: '$presentCount / $totalDaysInMonth',
                              subtitle: '$daysSoFar Days so far',
                              icon: Icons.event_available_rounded,
                              accentColor: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Consistency',
                              value: '$consistencyPct%',
                              subtitle: 'Monthly Score',
                              icon: Icons.bolt_rounded,
                              accentColor: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Monthly Calendar Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D29),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.greenAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Monthly Calendar Grid',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Weekday Labels Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children:
                                  [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ]
                                      .map(
                                        (day) => Expanded(
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 12),

                            // 7-Column Grid
                            _buildCalendarGrid(
                              selectedMonth: _selectedMonth,
                              totalDaysInMonth: totalDaysInMonth,
                              presentDays: presentDays,
                              now: now,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Detailed Log List for Selected Month
                      const Text(
                        'CHECK-IN LOGS THIS MONTH',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (monthDocs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D29),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No check-ins recorded for this month.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: monthDocs.length,
                          itemBuilder: (context, index) {
                            final data =
                                monthDocs[index].data() as Map<String, dynamic>;
                            final dateStr = data['date']?.toString() ?? '';
                            final timeStr = data['time']?.toString() ?? '';

                            String formattedDate = dateStr;
                            try {
                              final parsedDate = DateTime.parse(dateStr);
                              formattedDate = DateFormat(
                                'EEE, MMM dd, yyyy',
                              ).format(parsedDate);
                            } catch (_) {}

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
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.greenAccent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid({
    required DateTime selectedMonth,
    required int totalDaysInMonth,
    required Set<int> presentDays,
    required DateTime now,
  }) {
    final int firstWeekday = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    ).weekday; // 1=Mon, 7=Sun
    final int offset = firstWeekday - 1;
    final int itemCount = offset + totalDaysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < offset) {
          return const SizedBox.shrink();
        }

        final int day = index - offset + 1;
        final bool isPresent = presentDays.contains(day);
        final bool isToday =
            (selectedMonth.year == now.year &&
            selectedMonth.month == now.month &&
            day == now.day);

        return Container(
          decoration: BoxDecoration(
            color: isPresent
                ? Colors.greenAccent.withValues(alpha: 0.2)
                : const Color(0xFF12141C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPresent
                  ? Colors.greenAccent
                  : isToday
                  ? Colors.cyanAccent
                  : Colors.white10,
              width: isPresent || isToday ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: isPresent
                      ? Colors.greenAccent
                      : isToday
                      ? Colors.cyanAccent
                      : Colors.white70,
                  fontWeight: isPresent || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (isPresent) ...[
                const SizedBox(height: 2),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 10,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
