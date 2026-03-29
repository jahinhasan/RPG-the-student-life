import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rpg_student_life/services/admin_service.dart';
import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class TeacherGameEventScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final Map<String, dynamic> selectedClass;

  const TeacherGameEventScreen({
    super.key,
    required this.teacherId,
    required this.selectedClass,
  });

  @override
  ConsumerState<TeacherGameEventScreen> createState() => _TeacherGameEventScreenState();
}

class _TeacherGameEventScreenState extends ConsumerState<TeacherGameEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _xpCtrl = TextEditingController(text: '100');
  final _badgeCtrl = TextEditingController(text: 'Problem Solver');

  DateTime _eventDate = DateTime.now().add(const Duration(days: 3));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _xpCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classId = widget.selectedClass['id'] as String;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Game Events', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Event title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Event description'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _xpCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Winner XP'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _badgeCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Winner badge'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Event Date', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppTheme.textGray),
              ),
              trailing: const Icon(Icons.calendar_month, color: Colors.white),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _eventDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _eventDate = picked);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _createEvent(classId),
                child: const Text('Create Event'),
              ),
            ),
            const SizedBox(height: 20),
            Text('Class Events', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(adminServiceProvider).streamClassGameEvents(classId),
              builder: (context, snapshot) {
                final events = snapshot.data ?? const <Map<String, dynamic>>[];
                if (events.isEmpty) {
                  return Text('No events yet.', style: GoogleFonts.poppins(color: AppTheme.textGray));
                }

                return Column(
                  children: events.map((event) {
                    final winnerId = event['winnerStudentId']?.toString();
                    return Card(
                      color: AppTheme.cardColor,
                      child: ListTile(
                        title: Text(event['title'] ?? '-', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'XP ${event['rewardXp'] ?? 0} • Badge ${event['badge'] ?? '-'}\nWinner: ${winnerId ?? 'Not assigned'}',
                          style: const TextStyle(color: AppTheme.textGray),
                        ),
                        isThreeLine: true,
                        trailing: TextButton(
                          onPressed: () => _pickWinner(event, classId),
                          child: const Text('Pick Winner'),
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

  Future<void> _createEvent(String classId) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }

    await ref.read(adminServiceProvider).createGameEvent(
          teacherId: widget.teacherId,
          classId: classId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          rewardXp: int.tryParse(_xpCtrl.text.trim()) ?? 0,
          badge: _badgeCtrl.text.trim().isEmpty ? 'Problem Solver' : _badgeCtrl.text.trim(),
          eventDate: _eventDate,
        );

    if (!mounted) return;
    _titleCtrl.clear();
    _descCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created.')));
  }

  Future<void> _pickWinner(Map<String, dynamic> event, String classId) async {
    final students = await ref.read(studentsByClassProvider(classId).future);
    if (!mounted) return;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No students in class.')));
      return;
    }

    String selectedId = students.first['id'] as String;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Winner'),
              content: DropdownButtonFormField<String>(
                value: selectedId,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: Colors.white),
                items: students
                    .map((s) => DropdownMenuItem<String>(
                          value: s['id'] as String,
                          child: Text(
                            s['name']?.toString() ?? 'Student',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setStateDialog(() => selectedId = v);
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    final reward = (event['rewardXp'] is num) ? (event['rewardXp'] as num).toInt() : 0;
                    final badge = event['badge']?.toString() ?? 'Problem Solver';

                    await ref.read(xpServiceProvider).addXPToStudent(selectedId, reward);
                    await ref.read(xpServiceProvider).assignBadgeToStudent(selectedId, badge);
                    await FirebaseFirestore.instance.collection('game_events').doc(event['id'] as String).set({
                      'winnerStudentId': selectedId,
                      'winnerSelectedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Winner awarded successfully.')),
                    );
                  },
                  child: const Text('Award'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dec(String label) {
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
