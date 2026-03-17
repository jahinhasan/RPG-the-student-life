import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/admin_service.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final String? initialClassId;

  const MarksEntryScreen({super.key, this.initialClassId});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  String? _selectedClassId;
  String _assessmentType = _assessmentKeys.first;
  bool _submitting = false;

  final Map<String, TextEditingController> _marksControllers = {};

  static const List<String> _assessmentKeys = [
    'class_performance',
    'ct',
    'mid',
    'final',
  ];

  static const Map<String, String> _assessmentLabels = {
    'class_performance': 'Class Performance',
    'ct': 'CT',
    'mid': 'Mid',
    'final': 'Final',
  };

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
  }

  @override
  void dispose() {
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

    final assessmentBaseXp = _readAssessmentXp(settings['assessmentBaseXp']);
    final dropPenaltyMultiplier = _toDouble(settings['performanceDropPenaltyMultiplier'], 1.0);
    final dropPenaltyCapPercent = _readInt(settings['performanceDropPenaltyCapPercent'], 70);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Enter Marks', style: GoogleFonts.poppins(fontSize: 20)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: adminService.getTeacherClasses(teacher.uid),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = classSnapshot.data ?? [];
          if (classes.isEmpty) {
            return _buildNoClassState();
          }

          _selectedClassId ??= classes.first['id'] as String;

          final studentsAsync = ref.watch(studentsByClassProvider(_selectedClassId!));

          return studentsAsync.when(
            data: (students) => _buildContent(
              classes,
              students,
              assessmentBaseXp,
              dropPenaltyMultiplier,
              dropPenaltyCapPercent,
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
    Map<String, int> assessmentBaseXp,
    double dropPenaltyMultiplier,
    int dropPenaltyCapPercent,
  ) {
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
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _assessmentType,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Select Mark Type'),
            items: _assessmentKeys
                .map(
                  (key) => DropdownMenuItem<String>(
                    value: key,
                    child: Text(_assessmentLabels[key] ?? key),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _assessmentType = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildRulesCard(),
          const SizedBox(height: 14),
          if (students.isEmpty)
            Text('No students found in this class.', style: GoogleFonts.poppins(color: Colors.white70)),
          ...students.map((student) => _buildStudentMarkCard(student)).toList(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting || students.isEmpty
                  ? null
                  : () => _submit(
                        students,
                        assessmentBaseXp,
                        dropPenaltyMultiplier,
                        dropPenaltyCapPercent,
                      ),
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.save),
              label: Text(
                _submitting ? 'Submitting...' : 'Submit ${_assessmentLabels[_assessmentType]} Marks',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.studentAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x33F59E0B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66F59E0B)),
      ),
      child: Text(
        'Assessment: ${_assessmentLabels[_assessmentType]}\nXP reward is based on obtained percentage. If score drops vs previous same assessment, XP penalty is applied.',
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _buildStudentMarkCard(Map<String, dynamic> student) {
    final studentId = student['id'].toString();
    final controller = _marksControllers.putIfAbsent(studentId, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: [
          Row(
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
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Current XP: ${_toInt(student['xp'])}',
                      style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: '0 - 100'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildProgressGraph(studentId),
        ],
      ),
    );
  }

  Widget _buildProgressGraph(String studentId) {
    if (_selectedClassId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(adminServiceProvider).getStudentMarks(studentId: studentId, classId: _selectedClassId!),
      builder: (context, snapshot) {
        final marks = snapshot.data ?? {};
        final perf = _getPct(marks, 'class_performance');
        final ct = _getPct(marks, 'ct');
        final mid = _getPct(marks, 'mid');
        final fin = _getPct(marks, 'final');

        return Row(
          children: [
            _graphBar('P', perf, const Color(0xFF10B981)),
            _graphBar('CT', ct, const Color(0xFF3B82F6)),
            _graphBar('M', mid, const Color(0xFFF59E0B)),
            _graphBar('F', fin, const Color(0xFFEF4444)),
          ],
        );
      },
    );
  }

  Widget _graphBar(String label, double pct, Color color) {
    final clamped = pct.clamp(0, 100).toDouble();
    final normalized = clamped / 100.0;
    final height = math.max(6.0, 30.0 * normalized);

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 18,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _submit(
    List<Map<String, dynamic>> students,
    Map<String, int> assessmentBaseXp,
    double dropPenaltyMultiplier,
    int dropPenaltyCapPercent,
  ) async {
    if (_selectedClassId == null) return;

    setState(() => _submitting = true);

    int rewarded = 0;
    int deducted = 0;

    try {
      for (final student in students) {
        final studentId = student['id'].toString();
        final raw = _marksControllers[studentId]?.text.trim() ?? '';
        if (raw.isEmpty) {
          continue;
        }

        final obtained = (double.tryParse(raw) ?? 0).clamp(0.0, 100.0);
        if (obtained == 0) {
          continue;
        }

        final existing = await ref.read(adminServiceProvider).getStudentMarks(
              studentId: studentId,
              classId: _selectedClassId!,
            );

        final prevPct = _getPct(existing, _assessmentType);

        await ref.read(adminServiceProvider).recordMarks(
              studentId: studentId,
              classId: _selectedClassId!,
              assessmentName: _assessmentType,
              marksObtained: obtained,
              totalMarks: 100,
            );

        final xpReward = ((assessmentBaseXp[_assessmentType] ?? 100) * (obtained / 100)).round();
        int netXp = xpReward;

        if (prevPct > 0 && obtained < prevPct) {
          final dropPercent = ((prevPct - obtained) / prevPct) * 100;
          final scaledPenaltyPercent = (dropPercent * dropPenaltyMultiplier)
              .clamp(0.0, dropPenaltyCapPercent.toDouble());
          final penalty = (xpReward * (scaledPenaltyPercent / 100)).round();
          netXp = xpReward - penalty;
          deducted += penalty;
        }

        await ref.read(xpServiceProvider).addXPToStudent(studentId, netXp);
        rewarded += netXp;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Marks submitted. Total XP change: +$rewarded${deducted > 0 ? ' (deduction applied: $deducted)' : ''}.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit marks: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  double _getPct(Map<String, dynamic> marks, String key) {
    final item = marks[key];
    if (item is Map<String, dynamic>) {
      final percentage = item['percentage'];
      if (percentage is num) return percentage.toDouble();
      if (percentage is String) return double.tryParse(percentage) ?? 0;
      final obtained = item['obtained'];
      final total = item['total'];
      if (obtained is num && total is num && total > 0) {
        return (obtained / total) * 100;
      }
    }
    return 0;
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

  double _toDouble(Object? value, double fallback) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return fallback;
  }

  Map<String, int> _readAssessmentXp(Object? value) {
    final defaults = {
      'class_performance': 80,
      'ct': 100,
      'mid': 140,
      'final': 180,
    };

    if (value is! Map) {
      return defaults;
    }

    final merged = Map<String, int>.from(defaults);
    value.forEach((key, xp) {
      if (key is String && xp is num) {
        merged[key] = xp.toInt();
      }
    });
    return merged;
  }

  Widget _buildNoClassState() {
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
}
