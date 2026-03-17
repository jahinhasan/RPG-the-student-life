import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class TeacherAnnouncementScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final Map<String, dynamic>? initialClass;

  const TeacherAnnouncementScreen({
    super.key,
    required this.teacherId,
    this.initialClass,
  });

  @override
  ConsumerState<TeacherAnnouncementScreen> createState() => _TeacherAnnouncementScreenState();
}

class _TeacherAnnouncementScreenState extends ConsumerState<TeacherAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedClassId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClass?['id'] as String?;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = ref.read(adminServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        title: Text('Class Announcement', style: GoogleFonts.poppins(fontSize: 20)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: adminService.getTeacherClasses(widget.teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Text(
                'No classes assigned yet.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          if (_selectedClassId == null) {
            _selectedClassId = classes.first['id'] as String;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassPicker(classes),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  Text(
                    'Announcement Title',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'e.g., CT-2 Schedule Update'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Write the announcement that all students in this class should receive...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Message is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Message should be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : () => _send(classes),
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.send),
                      label: Text(
                        _sending ? 'Sending...' : 'Send to Class',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teacherAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassPicker(List<Map<String, dynamic>> classes) {
    return DropdownButtonFormField<String>(
      value: _selectedClassId,
      dropdownColor: AppTheme.cardColor,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Select Class',
      ),
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
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x33F59E0B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66F59E0B)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.megaphone, color: AppTheme.teacherAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This announcement will be saved and delivered to every student in the selected class.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(List<Map<String, dynamic>> classes) async {
    if (!_formKey.currentState!.validate() || _selectedClassId == null) {
      return;
    }

    setState(() => _sending = true);

    try {
      await ref.read(adminServiceProvider).createClassAnnouncement(
            teacherId: widget.teacherId,
            classId: _selectedClassId!,
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement sent successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send announcement: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _classLabel(Map<String, dynamic> classData) {
    final batch = classData['batchId']?.toString() ?? '-';
    final level = classData['levelId']?.toString() ?? '-';
    final term = classData['termId']?.toString() ?? '-';
    final section = classData['sectionName']?.toString() ?? '-';
    return 'Section $section • $batch • $level • $term';
  }
}
