import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';
import '../routes.dart';
import 'attendance_entry_screen.dart';
import 'marks_entry_screen.dart';
import 'teacher_announcement_screen.dart';
import 'teacher_mission_screen.dart';
import 'teacher_quiz_screen.dart';
import 'teacher_chat_screen.dart';
import 'teacher_game_event_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  String? _selectedClassId;

  Future<void> _logout(BuildContext context) async {
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.initial, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(backgroundColor: AppTheme.cardColor),
        body: Center(
          child: Text(
            'Please login as a teacher to continue.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(adminServiceProvider).getTeacherClasses(teacher.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final teacherClasses = snapshot.data ?? [];
            if (teacherClasses.isEmpty) {
              return _buildEmptyState(context);
            }

            final selectedClass = _resolveSelectedClass(teacherClasses);
            final selectedClassId = selectedClass['id'] as String;
            final studentsAsync = ref.watch(studentsByClassProvider(selectedClassId));
            final leaderboardAsync = ref.watch(leaderboardProvider);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, teacherClasses, selectedClass),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class Command Center',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildClassInfoCard(selectedClass),
                        const SizedBox(height: 20),
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(context, teacher.uid, selectedClass),
                        const SizedBox(height: 20),
                        Text(
                          'Class Progress Graph',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        studentsAsync.when(
                          data: (students) => leaderboardAsync.when(
                            data: (leaderboard) => _buildClassProgressSection(
                              students,
                              leaderboard,
                              selectedClassId,
                            ),
                            loading: () => _buildClassProgressSection(students, const [], selectedClassId),
                            error: (_, __) => _buildClassProgressSection(students, const [], selectedClassId),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => _buildErrorCard(error.toString()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _resolveSelectedClass(List<Map<String, dynamic>> classes) {
    if (_selectedClassId == null || !classes.any((c) => c['id'] == _selectedClassId)) {
      _selectedClassId = classes.first['id'] as String;
    }
    return classes.firstWhere((c) => c['id'] == _selectedClassId);
  }

  Widget _buildHeader(
    BuildContext context,
    List<Map<String, dynamic>> teacherClasses,
    Map<String, dynamic> selectedClass,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Pick class, then control attendance, marks, and announcements',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
                style: IconButton.styleFrom(backgroundColor: const Color(0x33EF4444)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Select Class (Level/Term/Section)',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
            ),
            items: teacherClasses
                .map(
                  (classData) => DropdownMenuItem<String>(
                    value: classData['id'] as String,
                    child: Text(_classLabel(classData)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Active: ${_classLabel(selectedClass)}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.teacherAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoCard(Map<String, dynamic> selectedClass) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x3310B981),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x6610B981)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.school2, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Teacher can update all student data for this class. Attendance, CT/Mid/Final/Performance marks, XP and ranking will be controlled from action cards below.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, String teacherId, Map<String, dynamic> selectedClass) {
    final actions = [
      {
        'label': 'Create Quest',
        'icon': LucideIcons.sword,
        'color1': const Color(0xFF06B6D4),
        'color2': const Color(0xFF0E7490),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TeacherMissionScreen(teacherId: teacherId)),
          );
        },
      },
      {
        'label': 'Daily Attendance',
        'icon': LucideIcons.checkCircle,
        'color1': const Color(0xFF10B981),
        'color2': const Color(0xFF059669),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceEntryScreen(initialClassId: selectedClass['id'] as String),
            ),
          );
        },
      },
      {
        'label': 'Enter Marks',
        'icon': LucideIcons.fileText,
        'color1': const Color(0xFF3B82F6),
        'color2': const Color(0xFF1D4ED8),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarksEntryScreen(initialClassId: selectedClass['id'] as String),
            ),
          );
        },
      },
      {
        'label': 'View Ranking',
        'icon': LucideIcons.trophy,
        'color1': const Color(0xFFF59E0B),
        'color2': const Color(0xFFD97706),
        'onTap': () {
          Navigator.pushNamed(context, '/leaderboard');
        },
      },
      {
        'label': 'Quiz / Exam',
        'icon': LucideIcons.fileQuestion,
        'color1': const Color(0xFF7C3AED),
        'color2': const Color(0xFF6D28D9),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherQuizScreen(
                teacherId: teacherId,
                initialClass: selectedClass,
              ),
            ),
          );
        },
      },
      {
        'label': 'Send Announcement',
        'icon': LucideIcons.bell,
        'color1': const Color(0xFF8B5CF6),
        'color2': const Color(0xFF6D28D9),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherAnnouncementScreen(
                teacherId: teacherId,
                initialClass: selectedClass,
              ),
            ),
          );
        },
      },
      {
        'label': 'Discussion Chat',
        'icon': LucideIcons.messagesSquare,
        'color1': const Color(0xFF14B8A6),
        'color2': const Color(0xFF0F766E),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherChatScreen(classId: selectedClass['id'] as String),
            ),
          );
        },
      },
      {
        'label': 'Game Events',
        'icon': LucideIcons.gamepad2,
        'color1': const Color(0xFFEF4444),
        'color2': const Color(0xFFB91C1C),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherGameEventScreen(
                teacherId: teacherId,
                selectedClass: selectedClass,
              ),
            ),
          );
        },
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.38,
      children: actions
          .map(
            (action) => InkWell(
              onTap: action['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [action['color1'] as Color, action['color2'] as Color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action['icon'] as IconData, color: Colors.white, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildClassProgressSection(
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> leaderboard,
    String classId,
  ) {
    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Text(
          'No students found in this class.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    final sortedStudents = [...students]
      ..sort((a, b) => _toInt(b['xp']).compareTo(_toInt(a['xp'])));
    final topXp = _toInt(sortedStudents.first['xp']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: sortedStudents.take(8).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final student = entry.value;
            final xp = _toInt(student['xp']);
            final level = _toInt(student['level']);
            final completedQuests = _toInt(student['completedQuests']) == 0
              ? _toInt(student['missionsCompleted'])
              : _toInt(student['completedQuests']);
            final leaderboardRank = _findLeaderboardRank(leaderboard, student['id']?.toString());
          final ratio = topXp == 0 ? 0.0 : (xp / topXp).clamp(0.0, 1.0);

          final studentId = student['id']?.toString() ?? '';
          final studentName = student['name']?.toString() ?? 'Student';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? AppTheme.teacherAccent : const Color(0xFF1F2937),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lvl $level • Quests $completedQuests • Rank ${leaderboardRank ?? '-'}',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 9,
                                backgroundColor: const Color(0xFF374151),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.studentAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$xp XP',
                        style: GoogleFonts.poppins(
                          color: AppTheme.teacherAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (studentId.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _miniActionButton(
                          label: '+10 XP',
                          color: const Color(0xFF10B981),
                          onTap: () => _applyXpToStudent(context, studentId, 10),
                        ),
                        _miniActionButton(
                          label: '-5 XP',
                          color: const Color(0xFFEF4444),
                          onTap: () => _applyXpToStudent(context, studentId, -5),
                        ),
                        _miniActionButton(
                          label: 'Unlock +1 Level',
                          color: const Color(0xFF3B82F6),
                          onTap: () => _unlockLevelForStudent(context, studentId, level),
                        ),
                        _miniActionButton(
                          label: 'Assign Badge',
                          color: const Color(0xFFF59E0B),
                          onTap: () => _assignBadgeToStudent(context, studentId, studentName),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _miniActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  int? _findLeaderboardRank(List<Map<String, dynamic>> leaderboard, String? uid) {
    if (uid == null) return null;
    for (final entry in leaderboard) {
      if (entry['uid']?.toString() == uid) {
        return _toInt(entry['rank']);
      }
    }
    return null;
  }

  Future<void> _applyXpToStudent(BuildContext context, String studentId, int amount) async {
    try {
      await ref.read(xpServiceProvider).addXPToStudent(studentId, amount);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(amount >= 0 ? 'Added $amount XP' : 'Penalty ${amount.abs()} XP applied')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('XP update failed: $e')));
    }
  }

  Future<void> _unlockLevelForStudent(BuildContext context, String studentId, int currentLevel) async {
    try {
      await ref.read(xpServiceProvider).setStudentLevelMinimum(studentId, currentLevel + 1);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlocked level ${currentLevel + 1} for student.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Level unlock failed: $e')));
    }
  }

  Future<void> _assignBadgeToStudent(BuildContext context, String studentId, String studentName) async {
    final badges = ['Problem Solver', 'Fast Learner', 'Team Leader'];
    String selected = badges.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text('Assign Badge to $studentName'),
              content: DropdownButtonFormField<String>(
                value: selected,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: Colors.white),
                items: badges
                    .map(
                      (b) => DropdownMenuItem<String>(
                        value: b,
                        child: Text(b, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setStateDialog(() => selected = value);
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    await ref.read(xpServiceProvider).assignBadgeToStudent(studentId, selected);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Badge "$selected" assigned to $studentName.')),
                    );
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x33EF4444),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66EF4444)),
      ),
      child: Text(
        'Failed to load class students: $error',
        style: GoogleFonts.poppins(color: Colors.white70),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.school2, color: AppTheme.textGray, size: 46),
            const SizedBox(height: 14),
            Text(
              'No classes assigned yet',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask admin to assign Batch/Level/Term classes to this teacher account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(LucideIcons.logOut),
              label: const Text('Back to Role Select'),
            ),
          ],
        ),
      ),
    );
  }

  String _classLabel(Map<String, dynamic> classData) {
    final batch = classData['batchId']?.toString() ?? '-';
    final level = classData['levelId']?.toString() ?? '-';
    final term = classData['termId']?.toString() ?? '-';
    final section = classData['sectionName']?.toString() ?? '-';
    return 'Section $section • $batch • $level • $term';
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
