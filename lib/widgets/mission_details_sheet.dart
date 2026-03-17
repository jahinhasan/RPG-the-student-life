import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

Future<void> showMissionDetailsSheet(BuildContext context, Map<String, dynamic> mission) {
  final title = (mission['title'] ?? 'Mission') as String;
  final description = (mission['desc'] ?? 'No description provided.') as String;
  final courseName = (mission['courseName'] ?? 'General Course') as String;
  final courseCode = (mission['courseCode'] ?? 'COURSE-101') as String;
  final teacherName = (mission['teacherName'] ?? 'Assigned Teacher') as String;
  final batch = (mission['batch'] ?? '2023') as String;
  final section = (mission['section'] ?? 'A') as String;
  final levelTerm = (mission['levelTerm'] ?? 'Level 1 / Term 1') as String;
  final dueDate = (mission['dueDate'] ?? 'No due date set') as String;
  final instructions = (mission['instructions'] ?? 'Complete the assigned work and submit it to your course teacher.') as String;
  final missionType = ((mission['type'] ?? 'daily') as String).toUpperCase();
  final xp = mission['xp'] ?? 0;
  final progress = (((mission['prog'] ?? 0.0) as num).toDouble() * 100).toInt();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: const BoxDecoration(
          color: AppTheme.bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTag(missionType, const Color(0xFF1D4ED8)),
                              _buildTag('+$xp XP', const Color(0xFF059669)),
                              _buildTag('$progress% done', const Color(0xFFD97706)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textGray,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPanel(
                  title: 'Assigned By',
                  icon: LucideIcons.userSquare2,
                  child: Column(
                    children: [
                      _buildDetailRow('Teacher', teacherName),
                      _buildDetailRow('Course', '$courseName ($courseCode)'),
                      _buildDetailRow('Due Date', dueDate),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildPanel(
                  title: 'Class Scope',
                  icon: LucideIcons.building2,
                  child: Column(
                    children: [
                      _buildDetailRow('Batch', batch),
                      _buildDetailRow('Section', section),
                      _buildDetailRow('Level / Term', levelTerm),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildPanel(
                  title: 'Instructions',
                  icon: LucideIcons.scrollText,
                  child: Text(
                    instructions,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildPanel({required String title, required IconData icon, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF1F2937)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.studentAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGray),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTag(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}