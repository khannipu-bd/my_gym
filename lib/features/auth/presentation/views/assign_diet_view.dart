import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssignDietView extends ConsumerStatefulWidget {
  const AssignDietView({super.key});

  @override
  ConsumerState<AssignDietView> createState() => _AssignDietViewState();
}

class _AssignDietViewState extends ConsumerState<AssignDietView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Track expanded member and selected template
  String? _expandedMemberDocId;
  String? _selectedTemplateDocId;
  Map<String, dynamic>? _selectedTemplateData;
  bool _isAssigning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 Assign selected template to member
  Future<void> _assignTemplateToMember({
    required String memberEmail,
    required String memberName,
    required String memberDocId,
  }) async {
    final docId = memberEmail.trim().isNotEmpty
        ? memberEmail.trim()
        : memberDocId;

    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid member identification! ⚠️'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedTemplateData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a diet template first! ⚠️'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final templateData = _selectedTemplateData!;
    final templateName = templateData['templateName'] ?? 'Custom Diet Plan';

    // Safely extract meal sections
    final mealsMap = (templateData['meals'] is Map)
        ? Map<String, dynamic>.from(templateData['meals'])
        : <String, dynamic>{};

    final breakfastData =
        mealsMap['breakfast'] ?? templateData['breakfast'] ?? {};
    final lunchData = mealsMap['lunch'] ?? templateData['lunch'] ?? {};
    final dinnerData = mealsMap['dinner'] ?? templateData['dinner'] ?? {};
    final snackData = mealsMap['snack'] ?? templateData['snack'] ?? {};

    setState(() => _isAssigning = true);

    try {
      await FirebaseFirestore.instance
          .collection('diet_charts')
          .doc(docId)
          .set({
            'userEmail': memberEmail,
            'templateName': templateName,
            'updatedAt': FieldValue.serverTimestamp(),
            'breakfast': breakfastData,
            'lunch': lunchData,
            'dinner': dinnerData,
            'snack': snackData,
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diet Plan successfully assigned to $memberName! 🥗'),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _expandedMemberDocId = null;
          _selectedTemplateDocId = null;
          _selectedTemplateData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign diet plan: $e'),
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
          'Assign Diet',
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
                  color: Colors.blueAccent,
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
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // 👥 Member List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isNotEqualTo: 'admin')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading members: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // 🔍 Apply Search Filter
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final gymId = (data['gymId'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? doc.id)
                      .toString()
                      .toLowerCase();

                  if (_searchQuery.isEmpty) return true;
                  return name.contains(_searchQuery) ||
                      gymId.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 54,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No members found in directory.'
                              : 'No matching members for "$_searchQuery"',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
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
                    final memberDocId = doc.id;

                    final name = data['name']?.toString() ?? 'Unknown Member';
                    final email = data['email']?.toString() ?? memberDocId;
                    final gymId = data['gymId']?.toString() ?? 'N/A';
                    final weight = data['weight']?.toString() ?? 'N/A';
                    final goal = data['goal']?.toString() ?? 'N/A';
                    final isExpanded = _expandedMemberDocId == memberDocId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D29),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isExpanded
                              ? Colors.blueAccent.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.05),
                          width: isExpanded ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Card Header Row (Tappable to expand)
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedMemberDocId = null;
                                  _selectedTemplateDocId = null;
                                  _selectedTemplateData = null;
                                } else {
                                  _expandedMemberDocId = memberDocId;
                                  _selectedTemplateDocId = null;
                                  _selectedTemplateData = null;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blueAccent
                                            .withValues(alpha: 0.15),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.blueAccent
                                                          .withValues(
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: isExpanded
                                            ? Colors.blueAccent
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildInfoBadge(
                                        icon: Icons.monitor_weight_outlined,
                                        label: 'Weight',
                                        value: weight,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildInfoBadge(
                                        icon: Icons.track_changes_rounded,
                                        label: 'Goal',
                                        value: goal,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 🔽 Interactive Assignment Panel
                          if (isExpanded) ...[
                            const Divider(color: Colors.white10, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SELECT DIET PLAN TEMPLATE',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 📜 Dropdown for templates
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('diet_templates')
                                        .orderBy('createdAt', descending: true)
                                        .snapshots(),
                                    builder: (context, templateSnapshot) {
                                      if (templateSnapshot.hasError) {
                                        return Text(
                                          'Error: ${templateSnapshot.error}',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        );
                                      }
                                      if (templateSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const LinearProgressIndicator(
                                          color: Colors.greenAccent,
                                        );
                                      }

                                      final templateDocs =
                                          templateSnapshot.data?.docs ?? [];

                                      if (templateDocs.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF12141C),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.white10,
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                color: Colors.orangeAccent,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'No diet templates available. Please create one first!',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF12141C),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.greenAccent
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedTemplateDocId,
                                            hint: const Text(
                                              'Choose a Diet Template...',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            dropdownColor: const Color(
                                              0xFF1A1D29,
                                            ),
                                            isExpanded: true,
                                            icon: const Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: Colors.greenAccent,
                                            ),
                                            items: templateDocs.map((tDoc) {
                                              final tData =
                                                  tDoc.data()
                                                      as Map<String, dynamic>;
                                              final tName =
                                                  tData['templateName'] ??
                                                  'Unnamed Plan';
                                              return DropdownMenuItem<String>(
                                                value: tDoc.id,
                                                child: Text(
                                                  tName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (selectedId) {
                                              if (selectedId != null) {
                                                final matchingDoc = templateDocs
                                                    .firstWhere(
                                                      (d) => d.id == selectedId,
                                                    );
                                                setState(() {
                                                  _selectedTemplateDocId =
                                                      selectedId;
                                                  _selectedTemplateData =
                                                      matchingDoc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Template Summary Card (if template selected)
                                  if (_selectedTemplateData != null) ...[
                                    _buildTemplateSummary(
                                      _selectedTemplateData!,
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // 🔘 Assign Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _isAssigning
                                          ? null
                                          : () => _assignTemplateToMember(
                                              memberEmail: email,
                                              memberName: name,
                                              memberDocId: memberDocId,
                                            ),
                                      icon: _isAssigning
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              color: Colors.white,
                                            ),
                                      label: Text(
                                        _isAssigning
                                            ? 'Assigning Plan...'
                                            : 'Assign Diet Plan',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        disabledBackgroundColor: Colors.green
                                            .withValues(alpha: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF12141C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSummary(Map<String, dynamic> templateData) {
    final mealsMap = (templateData['meals'] is Map)
        ? Map<String, dynamic>.from(templateData['meals'])
        : <String, dynamic>{};

    final breakfastFood =
        (mealsMap['breakfast']?['food'] ??
                templateData['breakfast']?['food'] ??
                '')
            .toString();
    final lunchFood =
        (mealsMap['lunch']?['food'] ?? templateData['lunch']?['food'] ?? '')
            .toString();
    final dinnerFood =
        (mealsMap['dinner']?['food'] ?? templateData['dinner']?['food'] ?? '')
            .toString();
    final snackFood =
        (mealsMap['snack']?['food'] ?? templateData['snack']?['food'] ?? '')
            .toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12141C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Summary Preview:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (breakfastFood.isNotEmpty)
            _buildSummaryMealRow(
              'Breakfast',
              breakfastFood,
              Colors.amberAccent,
            ),
          if (lunchFood.isNotEmpty)
            _buildSummaryMealRow('Lunch', lunchFood, Colors.orangeAccent),
          if (dinnerFood.isNotEmpty)
            _buildSummaryMealRow('Dinner', dinnerFood, Colors.purpleAccent),
          if (snackFood.isNotEmpty)
            _buildSummaryMealRow('Snack', snackFood, Colors.tealAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryMealRow(String title, String food, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              food,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
