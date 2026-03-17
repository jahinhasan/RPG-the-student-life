import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class TeacherQuizScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final Map<String, dynamic> initialClass;

  const TeacherQuizScreen({
    super.key,
    required this.teacherId,
    required this.initialClass,
  });

  @override
  ConsumerState<TeacherQuizScreen> createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends ConsumerState<TeacherQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController(text: '50');
  final _timeCtrl = TextEditingController(text: '20');

  String _type = 'mcq';
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClass['id'] as String?;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(adminServiceProvider).getTeacherClasses(widget.teacherId),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? const <Map<String, dynamic>>[];
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes.first['id'] as String;
        }

        return DropdownButtonFormField<String>(
          value: _selectedClassId,
          dropdownColor: AppTheme.cardColor,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Class'),
          items: classes
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c['id'] as String,
                  child: Text(
                    'Sec ${c['sectionName']} • ${c['batchId']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedClassId = v),
        );
      },
    );

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Create Quiz / Exam', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            classesAsync,
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Quiz Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rewardCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Reward XP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _timeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Time (min)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Type'),
              items: const [
                DropdownMenuItem(value: 'mcq', child: Text('MCQ', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'coding', child: Text('Coding Problem', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'mixed', child: Text('Mixed', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createQuiz,
                icon: const Icon(LucideIcons.plus),
                label: const Text('Create Quiz'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quizzes in Selected Class',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_selectedClassId != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: ref.read(adminServiceProvider).streamClassQuizzes(_selectedClassId!),
                builder: (context, snapshot) {
                  final quizzes = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (quizzes.isEmpty) {
                    return Text('No quizzes yet.', style: GoogleFonts.poppins(color: AppTheme.textGray));
                  }

                  return Column(
                    children: quizzes.map((q) {
                      return Card(
                        color: AppTheme.cardColor,
                        child: ListTile(
                          title: Text(q['title'] ?? '-', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${q['type'] ?? '-'} • ${q['timeLimitMinutes'] ?? 0} min • ${q['rewardXp'] ?? 0} XP',
                            style: const TextStyle(color: AppTheme.textGray),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createQuiz() async {
    if (_selectedClassId == null || _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class and title are required.')));
      return;
    }

    await ref.read(adminServiceProvider).createClassQuiz(
          teacherId: widget.teacherId,
          classId: _selectedClassId!,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          rewardXp: int.tryParse(_rewardCtrl.text.trim()) ?? 0,
          timeLimitMinutes: int.tryParse(_timeCtrl.text.trim()) ?? 20,
          type: _type,
        );

    if (!mounted) return;
    _titleCtrl.clear();
    _descCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz created successfully.')));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textGray),
      filled: true,
      fillColor: AppTheme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
