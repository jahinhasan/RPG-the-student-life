import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/admin_service.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';

class AttendanceEntryScreen extends ConsumerStatefulWidget {
  final String? initialClassId;

  const AttendanceEntryScreen({super.key, this.initialClassId});

  @override
  ConsumerState<AttendanceEntryScreen> createState() => _AttendanceEntryScreenState();
}

class _AttendanceEntryScreenState extends ConsumerState<AttendanceEntryScreen> {
  String? _selectedClassId;
  final Map<String, bool> _attendance = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
  }

  @override
  Widget build(BuildContext context) {
    final teacher = FirebaseAuth.instance.currentUser;
    if (teacher == null) {
      return _buildLoginPrompt();
    }

    final adminService = ref.read(adminServiceProvider);
    final xpSettingsAsync = ref.watch(xpSettingsProvider);
    final settings = xpSettingsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => AdminService.defaultXpSettings,
    );

    final presentXp = _readInt(settings['attendancePresentXp'], 10);
    final absentDeduction = _readInt(settings['attendanceAbsentPenalty'], 4);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Mark Attendance', style: GoogleFonts.poppins(fontSize: 20)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: adminService.getTeacherClasses(teacher.uid),
        builder: (context, classesSnapshot) {
          if (classesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = classesSnapshot.data ?? [];
          if (classes.isEmpty) {
            return _buildNoClassesState();
          }

          _selectedClassId ??= classes.first['id'] as String;

          final studentsAsync = ref.watch(studentsByClassProvider(_selectedClassId!));

          return studentsAsync.when(
            data: (students) => _buildContent(
              classes,
              students,
              teacher.uid,
              presentXp,
              absentDeduction,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Failed to load students: $error',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    List<Map<String, dynamic>> classes,
    List<Map<String, dynamic>> students,
    String teacherId,
    int presentXp,
    int absentDeduction,
  ) {
    final presentCount = _attendance.values.where((value) => value).length;
    final absentCount = _attendance.values.where((value) => !value).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Select Class'),
            items: classes
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
                _attendance.clear();
              });
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x333B82F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x663B82F6)),
            ),
            child: Text(
              'Present: +$presentXp XP | Absent: -$absentDeduction XP\nMarked Present: $presentCount | Marked Absent: $absentCount',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          if (students.isEmpty)
            Text('No students found in this class.', style: GoogleFonts.poppins(color: Colors.white70)),
          ...students.map((student) => _buildStudentCard(student)).toList(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting || students.isEmpty
                  ? null
                  : () => _submitAttendance(
                        students: students,
                        teacherId: teacherId,
                        presentXp: presentXp,
                        absentDeduction: absentDeduction,
                      ),
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.save),
              label: Text(
                _submitting ? 'Submitting...' : 'Submit Attendance',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentId = student['id'].toString();
    final markedPresent = _attendance[studentId];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: markedPresent == true
              ? const Color(0xFF10B981)
              : markedPresent == false
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF1F2937),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.studentAccent,
            child: Icon(LucideIcons.user, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']?.toString() ?? 'Unknown Student',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  'XP: ${_toInt(student['xp'])}',
                  style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildAttendanceButton(
                icon: LucideIcons.check,
                activeColor: const Color(0xFF10B981),
                active: markedPresent == true,
                onTap: () {
                  setState(() => _attendance[studentId] = true);
                },
              ),
              const SizedBox(width: 8),
              _buildAttendanceButton(
                icon: LucideIcons.x,
                activeColor: const Color(0xFFEF4444),
                active: markedPresent == false,
                onTap: () {
                  setState(() => _attendance[studentId] = false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton({
    required IconData icon,
    required Color activeColor,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: active ? activeColor : const Color(0xFF374151)),
        ),
        child: Icon(icon, size: 20, color: active ? Colors.white : Colors.white70),
      ),
    );
  }

  Future<void> _submitAttendance({
    required List<Map<String, dynamic>> students,
    required String teacherId,
    required int presentXp,
    required int absentDeduction,
  }) async {
    if (_selectedClassId == null) return;

    setState(() => _submitting = true);

    int rewarded = 0;
    int deducted = 0;

    try {
      for (final student in students) {
        final studentId = student['id'].toString();
        final isPresent = _attendance[studentId] ?? false;

        await ref.read(adminServiceProvider).recordAttendance(
              studentId: studentId,
              classId: _selectedClassId!,
              date: DateTime.now(),
              isPresent: isPresent,
            );

        final xpDelta = isPresent ? presentXp : -absentDeduction;
        await ref.read(xpServiceProvider).addXPToStudent(studentId, xpDelta);

        if (isPresent) {
          rewarded += 1;
        } else {
          deducted += 1;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance submitted: $rewarded rewarded (+$presentXp XP), $deducted deducted (-$absentDeduction XP).',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit attendance: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildNoClassesState() {
    return Center(
      child: Text('No classes assigned to this teacher.', style: GoogleFonts.poppins(color: Colors.white70)),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(backgroundColor: AppTheme.cardColor),
      body: Center(
        child: Text('Please login first.', style: GoogleFonts.poppins(color: Colors.white70)),
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

  int _readInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
