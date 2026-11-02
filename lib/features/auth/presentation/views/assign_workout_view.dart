import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssignWorkoutView extends ConsumerStatefulWidget {
  const AssignWorkoutView({super.key});

  @override
  ConsumerState<AssignWorkoutView> createState() => _AssignWorkoutViewState();
}

class _AssignWorkoutViewState extends ConsumerState<AssignWorkoutView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🆔 মেম্বারের কার্ড এক্সপ্যান্ড ও সিলেক্টেড টেমপ্লেট আইডি ট্র্যাক করার আইডি
  String? _expandedMemberDocId;
  String? _selectedTemplateDocId;
  bool _isAssigning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 টেমপ্লেট ডাটা নির্দিষ্ট মেম্বারের workout_charts এ অ্যাসাইন করার মেথড
  Future<void> _assignTemplateToMember({
    required String memberEmail,
    required String memberName,
    required Map<String, dynamic> templateData,
  }) async {
    final docId = memberEmail.trim().isNotEmpty
        ? memberEmail.trim()
        : _expandedMemberDocId;

    if (docId == null || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid member identification! ⚠️'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final templateName = templateData['templateName'] ?? 'Workout Plan';
    final duration = templateData['duration'] ?? 'Estimated Time';
    final daysList = (templateData['days'] is List)
        ? (templateData['days'] as List)
        : [];

    // 🔄 workout_charts কালেকশনের উপযোগী day_routines ম্যাপ তৈরি
    Map<String, dynamic> dayRoutinesMap = {};
    for (var day in daysList) {
      if (day is Map<String, dynamic>) {
        final dayName = day['dayName'] ?? 'Day';
        final exercises = day['exercises'] ?? [];
        dayRoutinesMap[dayName] = {'exercises': exercises};
      }
    }

    setState(() => _isAssigning = true);

    try {
      await FirebaseFirestore.instance
          .collection('workout_charts')
          .doc(docId)
          .set({
            'userEmail': memberEmail,
            'workoutTitle': templateName,
            'duration': duration,
            'day_routines': dayRoutinesMap,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan successfully assigned to $memberName! 🔥'),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _expandedMemberDocId = null;
          _selectedTemplateDocId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign workout plan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: const Text(
          'Assign Workout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Top Search Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1A1D29),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search member by Name, Gym ID, or Email...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF12141C),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.greenAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 👥 Member List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading members: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                final userDocs = snapshot.data?.docs ?? [];

                // 🔍 Search and role filtering
                final filteredDocs = userDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? doc.id)
                      .toString()
                      .toLowerCase();
                  final gymId = (data['gymId'] ?? '').toString().toLowerCase();
                  final role = (data['role'] ?? '').toString().toLowerCase();

                  if (role == 'admin') return false;

                  if (_searchQuery.isEmpty) return true;

                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      gymId.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 56,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No gym members found matching your search.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final name = data['name'] ?? 'Unknown Member';
                    final email = data['email'] ?? docId;
                    final gymId = data['gymId'] ?? 'N/A';
                    final weight = data['weight'] ?? 'N/A';
                    final goal = data['goal'] ?? 'N/A';

                    final isExpanded = _expandedMemberDocId == docId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D29),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isExpanded
                              ? Colors.greenAccent.withOpacity(0.5)
                              : Colors.white.withOpacity(0.05),
                          width: isExpanded ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 👤 Member Info Tile Header
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedMemberDocId = null;
                                  _selectedTemplateDocId = null;
                                } else {
                                  _expandedMemberDocId = docId;
                                  _selectedTemplateDocId = null;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.greenAccent
                                        .withOpacity(0.15),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'M',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 🏷️ Gym ID Badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent
                                                    .withOpacity(0.18),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'ID: $gymId',
                                                style: const TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.monitor_weight_outlined,
                                              size: 14,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Weight: $weight',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.ads_click_rounded,
                                              size: 14,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Goal: $goal',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: Colors.greenAccent,
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 🔽 Interactive Assignment Panel when expanded
                          if (isExpanded)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12141C),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_turned_in_rounded,
                                        color: Colors.greenAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Select Workout Template for $name:',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // 📜 Workout Templates Stream & Dropdown
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('workout_templates')
                                        .orderBy('createdAt', descending: true)
                                        .snapshots(),
                                    builder: (context, templateSnapshot) {
                                      if (templateSnapshot.hasError) {
                                        return Text(
                                          'Error: ${templateSnapshot.error}',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        );
                                      }

                                      if (templateSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const LinearProgressIndicator(
                                          color: Colors.greenAccent,
                                        );
                                      }

                                      final templates =
                                          templateSnapshot.data?.docs ?? [];

                                      if (templates.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'No workout templates found. Create a template first!',
                                                  style: TextStyle(
                                                    color: Colors.amber,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      // Ensure selected value is valid
                                      final templateDocIds = templates
                                          .map((e) => e.id)
                                          .toList();
                                      if (_selectedTemplateDocId != null &&
                                          !templateDocIds.contains(
                                            _selectedTemplateDocId,
                                          )) {
                                        _selectedTemplateDocId = null;
                                      }

                                      // Selected template object
                                      Map<String, dynamic>?
                                      selectedTemplateData;
                                      if (_selectedTemplateDocId != null) {
                                        final match = templates.firstWhere(
                                          (t) => t.id == _selectedTemplateDocId,
                                        );
                                        selectedTemplateData =
                                            match.data()
                                                as Map<String, dynamic>;
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A1D29),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.greenAccent
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedTemplateDocId,
                                                hint: const Text(
                                                  'Select a Workout Template...',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                dropdownColor: const Color(
                                                  0xFF1A1D29,
                                                ),
                                                isExpanded: true,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                                items: templates.map((tDoc) {
                                                  final tData =
                                                      tDoc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final tName =
                                                      tData['templateName'] ??
                                                      'Unnamed Plan';
                                                  final tDur =
                                                      tData['duration'] ?? '';
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: tDoc.id,
                                                    child: Text(
                                                      '$tName (${tDur.isNotEmpty ? tDur : 'N/A'})',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedTemplateDocId =
                                                        val;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // 👁️ Template Preview Summary if selected
                                          if (selectedTemplateData != null) ...[
                                            _buildTemplatePreview(
                                              selectedTemplateData,
                                            ),
                                            const SizedBox(height: 14),
                                          ],

                                          // 🎯 Assign Plan Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 48,
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  (_selectedTemplateDocId ==
                                                          null ||
                                                      _isAssigning)
                                                  ? null
                                                  : () {
                                                      if (selectedTemplateData !=
                                                          null) {
                                                        _assignTemplateToMember(
                                                          memberEmail: email,
                                                          memberName: name,
                                                          templateData:
                                                              selectedTemplateData,
                                                        );
                                                      }
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.greenAccent,
                                                disabledBackgroundColor:
                                                    Colors.white10,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                              icon: _isAssigning
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.black,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      color: Colors.black,
                                                      size: 20,
                                                    ),
                                              label: Text(
                                                _isAssigning
                                                    ? 'Assigning Plan...'
                                                    : 'Assign Plan to $name',
                                                style: TextStyle(
                                                  color:
                                                      _selectedTemplateDocId ==
                                                          null
                                                      ? Colors.grey
                                                      : Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreview(Map<String, dynamic> templateData) {
    final name = templateData['templateName'] ?? '';
    final duration = templateData['duration'] ?? '';
    final days = (templateData['days'] is List)
        ? (templateData['days'] as List)
        : [];

    int totalExercises = 0;
    for (var day in days) {
      if (day is Map && day['exercises'] is List) {
        totalExercises += (day['exercises'] as List).length;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.blueAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Summary: $name • $duration • ${days.length} Routine Days • $totalExercises Total Exercises',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
