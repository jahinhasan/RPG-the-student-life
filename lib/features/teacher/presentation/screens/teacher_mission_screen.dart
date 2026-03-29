import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rpg_student_life/services/admin_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class TeacherMissionScreen extends ConsumerWidget {
  final String teacherId;

  const TeacherMissionScreen({required this.teacherId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          backgroundColor: AppTheme.studentAccent,
          title: Text(
            'Mission Management',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'My Classes'),
              Tab(text: 'Create Mission'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TeacherClassesTab(teacherId: teacherId),
            _CreateMissionTab(teacherId: teacherId),
          ],
        ),
      ),
    );
  }
}

// ==================== Tab 1: Teacher's Classes ====================

class _TeacherClassesTab extends ConsumerWidget {
  final String teacherId;

  const _TeacherClassesTab({required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: adminService.getTeacherClasses(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final classes = snapshot.data ?? [];

        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.inbox,
                    size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'No classes assigned',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index];
            return ClassCard(classData: classData, teacherId: teacherId);
          },
        );
      },
    );
  }
}

class ClassCard extends ConsumerWidget {
  final Map<String, dynamic> classData;
  final String teacherId;

  const ClassCard({
    required this.classData,
    required this.teacherId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchId = classData['batchId'] as String;
    final levelId = classData['levelId'] as String;
    final termId = classData['termId'] as String;
    final sectionName = classData['sectionName'] as String;
    final classId = classData['id'] as String;

    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        textColor: Colors.white,
        iconColor: Colors.white70,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.studentAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.book, color: Colors.white, size: 20),
        ),
        title: Text(
          'Section $sectionName',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Batch $batchId • Level $levelId • Term $termId',
          style: GoogleFonts.sora(color: AppTheme.textGray),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.eye, color: Colors.white70),
          onPressed: () => _showStudentRoster(context, ref, classId),
        ),
      ),
    );
  }

  void _showStudentRoster(BuildContext context, WidgetRef ref, String classId) {
    showDialog(
      context: context,
      builder: (ctx) => StudentRosterDialog(classId: classId),
    );
  }
}

class StudentRosterDialog extends ConsumerWidget {
  final String classId;

  const StudentRosterDialog({required this.classId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsByClassProvider(classId));

    return Dialog(
      backgroundColor: AppTheme.bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Class Roster',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return Center(
                    child: Text(
                      'No students enrolled',
                      style: GoogleFonts.sora(color: AppTheme.textGray),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      textColor: Colors.white,
                      iconColor: Colors.white70,
                      leading: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: AppTheme.studentAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            student['name'][0].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        student['name'] ?? 'Unknown',
                        style: GoogleFonts.sora(color: Colors.white),
                      ),
                      subtitle: Text(
                        student['email'] ?? '',
                        style: GoogleFonts.sora(color: AppTheme.textGray),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Text(
                  'Error: $err',
                  style: GoogleFonts.sora(color: Colors.redAccent),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Tab 2: Create Mission ====================

class _CreateMissionTab extends ConsumerStatefulWidget {
  final String teacherId;

  const _CreateMissionTab({required this.teacherId});

  @override
  ConsumerState<_CreateMissionTab> createState() => _CreateMissionTabState();
}

class _CreateMissionTabState extends ConsumerState<_CreateMissionTab> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final instructionsController = TextEditingController();
  final xpController = TextEditingController();
  final courseNameController = TextEditingController();
  final courseCodeController = TextEditingController();

  String? selectedClassId;
  String selectedType = 'daily';
  String selectedDifficulty = 'medium';
  DateTime? selectedDueDate;

  @override
  Widget build(BuildContext context) {
    final adminService = ref.read(adminServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: adminService.getTeacherClasses(widget.teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Selection
              Text(
                'Select Class',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedClassId,
                items: classes
                    .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text(
                              'Section ${c['sectionName']} • Batch ${c['batchId']}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedClassId = value);
                },
                decoration: InputDecoration(
                  hintText: 'Choose a class',
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Mission Type
              Text(
                'Mission Type',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['daily', 'weekly', 'assignment'].map((type) {
                  return ChoiceChip(
                    label: Text(type.toUpperCase()),
                    selected: selectedType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => selectedType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Difficulty Level
              Text(
                'Difficulty Level',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['easy', 'medium', 'hard'].map((difficulty) {
                  return ChoiceChip(
                    label: Text(difficulty.toUpperCase()),
                    selected: selectedDifficulty == difficulty,
                    onSelected: (selected) {
                      if (selected) setState(() => selectedDifficulty = difficulty);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Mission Title *',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Linear Equations Problem Set',
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Description *',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Brief description of the mission',
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Instructions
              Text(
                'Instructions *',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: instructionsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Detailed instructions for completing the mission',
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // XP Reward
              Text(
                'XP Reward *',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: xpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 100',
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Course Info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Name',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: courseNameController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Calculus I',
                            filled: true,
                            fillColor: AppTheme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Code',
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: courseCodeController,
                          decoration: InputDecoration(
                            hintText: 'e.g., MATH-211',
                            filled: true,
                            fillColor: AppTheme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Due Date (for assignments)
              Text(
                'Due Date${selectedType == 'assignment' ? ' *' : ''}',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => selectedDueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 18),
                      const SizedBox(width: 8),
                      Text(selectedDueDate == null
                          ? 'Select due date'
                          : '${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: () => _submitMission(context, ref, adminService),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppTheme.studentAccent,
                ),
                child: Text(
                  'Create Mission',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitMission(
      BuildContext context, WidgetRef ref, AdminService adminService) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        instructionsController.text.isEmpty ||
        xpController.text.isEmpty ||
        selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (selectedType == 'assignment' && selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date is required for assignments')),
      );
      return;
    }

    try {
      await adminService.createTeacherMission(
        teacherId: widget.teacherId,
        classId: selectedClassId!,
        title: titleController.text,
        description: descriptionController.text,
        xp: int.parse(xpController.text),
        dueDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
        instructions: instructionsController.text,
        type: selectedType,
        difficulty: selectedDifficulty,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission created successfully!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    instructionsController.clear();
    xpController.clear();
    courseNameController.clear();
    courseCodeController.clear();
    setState(() {
      selectedClassId = null;
      selectedType = 'daily';
      selectedDifficulty = 'medium';
      selectedDueDate = null;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    instructionsController.dispose();
    xpController.dispose();
    courseNameController.dispose();
    courseCodeController.dispose();
    super.dispose();
  }
}
