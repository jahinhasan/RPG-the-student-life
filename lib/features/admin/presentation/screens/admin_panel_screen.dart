import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rpg_student_life/services/admin_service.dart';
import 'package:rpg_student_life/services/dev_seed_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';
import 'package:rpg_student_life/routes.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _seedDemoData(BuildContext context, WidgetRef ref) async {
    final shouldSeed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Generate Test Data'),
            content: const Text(
              'This will create/update demo users, classes, missions, quizzes, notifications, and battle questions for testing. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Generate'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSeed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating demo Firestore data...')),
    );

    try {
      final result = await ref.read(devSeedServiceProvider).seedDemoData();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Done: ${result.users} users, ${result.missions} missions, ${result.quizzes} quizzes, ${result.battleQuestions} battle questions.',
          ),
        ),
      );

      ref.invalidate(batchesProvider);
      ref.invalidate(levelsProvider);
      ref.invalidate(termsProvider);
      ref.invalidate(classesProvider);
      ref.invalidate(studentsProvider);
      ref.invalidate(teachersProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo seed failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is admin (will be implemented in auth flow)
    // For now, scaffold is open to all

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          backgroundColor: AppTheme.studentAccent,
          title: Text(
            'Admin Panel',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Generate Test Data',
              onPressed: () => _seedDemoData(context, ref),
              icon: const Icon(LucideIcons.database, color: Colors.white),
            ),
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(LucideIcons.logOut, size: 18, color: Colors.white),
              label: Text(
                'Logout',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.sora(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.sora(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            tabs: [
              Tab(text: 'Hierarchy'),
              Tab(text: 'Teachers'),
              Tab(text: 'Classes'),
              Tab(text: 'Students'),
              Tab(text: 'Analytics'),
              Tab(text: 'XP Rules'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _HierarchyTab(),
            const _TeachersTab(),
            const _ClassesTab(),
            const _StudentsTab(),
            const _AnalyticsTab(),
            const _XpRulesTab(),
          ],
        ),
      ),
    );
  }
}

// ==================== 1. Hierarchy Tab (Batch/Level/Term Management) ====================

class _HierarchyTab extends ConsumerWidget {
  const _HierarchyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Batches',
            icon: LucideIcons.users,
            onAdd: () => _showAddBatchDialog(context, ref),
            content: Consumer(
              builder: (context, ref, child) {
                final batchesAsync = ref.watch(batchesProvider);
                return batchesAsync.when(
                  data: (batches) {
                    return Column(
                      children: batches
                          .map((batch) => _buildListTile(
                                title: 'Batch ${batch['year']}',
                                subtitle: 'ID: ${batch['id']}',
                                onDelete: () => _confirmDelete(
                                  context,
                                  ref,
                                  label: 'Batch ${batch['year']}',
                                  onConfirm: () async {
                                    await ref.read(adminServiceProvider).deleteBatch(batch['id'] as String);
                                    ref.invalidate(batchesProvider);
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, st) => Text('Error: $err'),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Levels',
            icon: LucideIcons.layers,
            onAdd: () => _showAddLevelDialog(context, ref),
            content: Consumer(
              builder: (context, ref, child) {
                final levelsAsync = ref.watch(levelsProvider);
                return levelsAsync.when(
                  data: (levels) {
                    return Column(
                      children: levels
                          .map((level) => _buildListTile(
                                title: 'Level ${level['levelNumber']}',
                                subtitle: 'ID: ${level['id']}',
                                onDelete: () => _confirmDelete(
                                  context,
                                  ref,
                                  label: 'Level ${level['levelNumber']}',
                                  onConfirm: () async {
                                    await ref.read(adminServiceProvider).deleteLevel(level['id'] as String);
                                    ref.invalidate(levelsProvider);
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, st) => Text('Error: $err'),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Terms',
            icon: LucideIcons.calendar,
            onAdd: () => _showAddTermDialog(context, ref),
            content: Consumer(
              builder: (context, ref, child) {
                final termsAsync = ref.watch(termsProvider);
                return termsAsync.when(
                  data: (terms) {
                    return Column(
                      children: terms
                          .map((term) => _buildListTile(
                                title: term['termName'] ?? 'Unknown Term',
                                subtitle: 'Term ${term['termNumber']}',
                                onDelete: () => _confirmDelete(
                                  context,
                                  ref,
                                  label: term['termName'] ?? 'this term',
                                  onConfirm: () async {
                                    await ref.read(adminServiceProvider).deleteTerm(term['id'] as String);
                                    ref.invalidate(termsProvider);
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, st) => Text('Error: $err'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBatchDialog(BuildContext context, WidgetRef ref) {
    final yearController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Batch'),
        content: TextField(
          controller: yearController,
          decoration: const InputDecoration(hintText: 'Year (e.g., 2023)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final admin = ref.read(adminServiceProvider);
              await admin.createBatch(
                batchId: 'batch_${yearController.text}',
                year: int.parse(yearController.text),
              );
              Navigator.pop(ctx);
              ref.invalidate(batchesProvider);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddLevelDialog(BuildContext context, WidgetRef ref) {
    final levelController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Level'),
        content: TextField(
          controller: levelController,
          decoration: const InputDecoration(hintText: 'Level Number'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final admin = ref.read(adminServiceProvider);
              await admin.createLevel(
                levelId: 'level_${levelController.text}',
                levelNumber: int.parse(levelController.text),
              );
              Navigator.pop(ctx);
              ref.invalidate(levelsProvider);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTermDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Term'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Term Name (e.g., Spring)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(hintText: 'Term Number'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final admin = ref.read(adminServiceProvider);
              await admin.createTerm(
                termId: 'term_${numberController.text}',
                termName: nameController.text,
                termNumber: int.parse(numberController.text),
              );
              Navigator.pop(ctx);
              ref.invalidate(termsProvider);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "$label"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ==================== 2. Teachers Tab ====================

class _TeachersTab extends ConsumerWidget {
  const _TeachersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'All Teachers',
            icon: LucideIcons.briefcase,
            content: Consumer(
              builder: (context, ref, child) {
                final teachersAsync = ref.watch(teachersProvider);
                return teachersAsync.when(
                  data: (teachers) {
                    if (teachers.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No teachers found'),
                        ),
                      );
                    }
                    return Column(
                      children: teachers
                          .map((teacher) => TeacherTile(teacher: teacher))
                          .toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, st) => Text('Error: $err'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherTile extends ConsumerWidget {
  final Map<String, dynamic> teacher;

  const TeacherTile({required this.teacher, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
        ),
        title: Text(
          teacher['name'] ?? 'Unknown',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          teacher['email'] ?? '',
          style: GoogleFonts.sora(color: AppTheme.textGray),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onTeacherActionSelected(context, ref, value),
          itemBuilder: (ctx) => const [
            PopupMenuItem<String>(
              value: 'assign',
              child: Text('Assign Classes'),
            ),
            PopupMenuItem<String>(
              value: 'missions',
              child: Text('View Mission History'),
            ),
            PopupMenuItem<String>(
              value: 'promote',
              child: Text('Promote to Admin'),
            ),
          ],
        ),
      ),
    );
  }

  void _onTeacherActionSelected(BuildContext context, WidgetRef ref, String action) {
    final teacherId = teacher['id'] as String;
    final teacherName = (teacher['name'] as String?) ?? 'Teacher';

    if (action == 'assign') {
      _showAssignClassesDialog(context, ref, teacherId);
      return;
    }

    if (action == 'missions') {
      _showMissionHistoryDialog(context, ref, teacherId, teacherName);
      return;
    }

    if (action == 'promote') {
      _showPromoteToAdminDialog(context, ref, teacherId, teacherName);
    }
  }

  void _showAssignClassesDialog(BuildContext context, WidgetRef ref, String teacherId) {
    final currentAssigned = Set<String>.from(teacher['assignedClassIds'] ?? const <String>[]);

    showDialog(
      context: context,
      builder: (ctx) {
        final selectedClassIds = Set<String>.from(currentAssigned);

        return StatefulBuilder(
          builder: (ctx, setState) {
            final classesAsync = ref.watch(classesProvider);
            final batches = ref.watch(batchesProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);
            final levels = ref.watch(levelsProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);
            final terms = ref.watch(termsProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);

            return AlertDialog(
              title: const Text('Assign Classes'),
              content: SizedBox(
                width: 420,
                child: classesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Error loading classes: $error'),
                  data: (classes) {
                    if (classes.isEmpty) {
                      return Text(
                        'No classes found. Create classes first from the Classes tab.',
                        style: GoogleFonts.sora(color: AppTheme.textGray),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: classes.map((classData) {
                          final classId = classData['id'] as String;
                          final label = _buildClassDisplayName(
                            classData,
                            batches: batches,
                            levels: levels,
                            terms: terms,
                          );

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selectedClassIds.contains(classId),
                            activeColor: AppTheme.studentAccent,
                            checkColor: Colors.white,
                            title: Text(label, style: GoogleFonts.sora(fontSize: 13)),
                            subtitle: Text(classId, style: GoogleFonts.sora(fontSize: 11, color: AppTheme.textGray)),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedClassIds.add(classId);
                                } else {
                                  selectedClassIds.remove(classId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final classes = ref.read(classesProvider).maybeWhen(
                          data: (value) => value,
                          orElse: () => const <Map<String, dynamic>>[],
                        );
                    final admin = ref.read(adminServiceProvider);

                    if (classes.isEmpty) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('No classes found to assign.')),
                      );
                      return;
                    }

                    try {
                      for (final classData in classes) {
                        final classId = classData['id'] as String;
                        final teacherIds = List<String>.from(classData['assignedTeacherIds'] ?? const <String>[]);
                        final shouldAssign = selectedClassIds.contains(classId);
                        final isAssigned = teacherIds.contains(teacherId);

                        if (shouldAssign && !isAssigned) {
                          teacherIds.add(teacherId);
                          await admin.assignTeachersToClass(classId: classId, teacherIds: teacherIds);
                        }

                        if (!shouldAssign && isAssigned) {
                          await admin.removeTeacherFromClass(classId: classId, teacherId: teacherId);
                        }
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      ref.invalidate(classesProvider);
                      ref.invalidate(teachersProvider);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teacher class assignments updated.')),
                      );
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed to update assignments: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMissionHistoryDialog(BuildContext context, WidgetRef ref, String teacherId, String teacherName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Missions by $teacherName'),
          content: SizedBox(
            width: 440,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(adminServiceProvider).streamTeacherMissions(teacherId),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent));
                }
                final missions = snapshot.data ?? [];
                if (missions.isEmpty) {
                  return Text(
                    'No missions created by this teacher yet.',
                    style: GoogleFonts.sora(color: AppTheme.textGray),
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: missions.map((m) {
                      return Card(
                        color: AppTheme.cardColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            m['title'] ?? 'Untitled',
                            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${m['type'] ?? 'mission'} • ${m['xp'] ?? 0} XP\nClass: ${m['classId'] ?? '-'}',
                            style: GoogleFonts.sora(color: AppTheme.textGray, fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.studentAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${m['xp'] ?? 0} XP',
                              style: GoogleFonts.sora(color: AppTheme.studentAccent, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showPromoteToAdminDialog(BuildContext context, WidgetRef ref, String teacherId, String teacherName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
          'Are you sure you want to promote $teacherName to Admin?\n\nThis will change their role and grant full admin access.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await ref.read(adminServiceProvider).promoteToAdmin(teacherId);
              ref.invalidate(teachersProvider);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$teacherName promoted to Admin.')),
              );
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }
}

// ==================== 3. Classes Tab ====================

class _ClassesTab extends ConsumerWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final batches = ref.watch(batchesProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);
    final levels = ref.watch(levelsProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);
    final terms = ref.watch(termsProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Classes',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateClassDialog(context, ref),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Create Class'),
          ),
          const SizedBox(height: 16),
          classesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error loading classes: $error'),
            data: (classes) {
              if (classes.isEmpty) {
                return Text(
                  'No class created yet.',
                  style: GoogleFonts.sora(color: AppTheme.textGray),
                );
              }

              return Column(
                children: classes.map((classData) {
                  final className = _buildClassDisplayName(
                    classData,
                    batches: batches,
                    levels: levels,
                    terms: terms,
                  );
                  final assignedTeacherIds = List<String>.from(classData['assignedTeacherIds'] ?? const <String>[]);

                  return Card(
                    color: AppTheme.cardColor,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(className, style: GoogleFonts.sora(color: Colors.white)),
                      subtitle: Text(
                        'Assigned teachers: ${assignedTeacherIds.length}',
                        style: GoogleFonts.sora(color: AppTheme.textGray),
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                        tooltip: 'Delete class',
                        onPressed: () => _confirmDeleteClass(context, ref, classData['id'] as String, className),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context, WidgetRef ref) {
    String? selectedBatchId;
    String? selectedLevelId;
    String? selectedTermId;
    final sectionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final batchesAsync = ref.watch(batchesProvider);
            final levelsAsync = ref.watch(levelsProvider);
            final termsAsync = ref.watch(termsProvider);

            final batches = batchesAsync.value ?? const <Map<String, dynamic>>[];
            final levels = levelsAsync.value ?? const <Map<String, dynamic>>[];
            final terms = termsAsync.value ?? const <Map<String, dynamic>>[];

            if (selectedBatchId == null && batches.isNotEmpty) {
              selectedBatchId = batches.first['id'] as String;
            }
            if (selectedLevelId == null && levels.isNotEmpty) {
              selectedLevelId = levels.first['id'] as String;
            }
            if (selectedTermId == null && terms.isNotEmpty) {
              selectedTermId = terms.first['id'] as String;
            }

            return AlertDialog(
              title: const Text('Create Class'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                      value: selectedBatchId,
                      decoration: const InputDecoration(labelText: 'Batch'),
                      items: batches
                          .map(
                            (batch) => DropdownMenuItem<String>(
                              value: batch['id'] as String,
                              child: Text('Batch ${batch['year']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedBatchId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedLevelId,
                      decoration: const InputDecoration(labelText: 'Level'),
                      items: levels
                          .map(
                            (level) => DropdownMenuItem<String>(
                              value: level['id'] as String,
                              child: Text('Level ${level['levelNumber']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedLevelId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedTermId,
                      decoration: const InputDecoration(labelText: 'Term'),
                      items: terms
                          .map(
                            (term) => DropdownMenuItem<String>(
                              value: term['id'] as String,
                              child: Text('${term['termName']} (Term ${term['termNumber']})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedTermId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        hintText: 'A',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create batch, level, and term first if dropdowns are empty.',
                      style: GoogleFonts.sora(fontSize: 11, color: AppTheme.textGray),
                    ),
                  ],
                ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final section = sectionController.text.trim().toUpperCase();
                    if (selectedBatchId == null ||
                        selectedLevelId == null ||
                        selectedTermId == null ||
                        section.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select batch/level/term and enter section.')),
                      );
                      return;
                    }

                    final normalizedSection = section
                        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
                        .replaceAll(RegExp(r'_+'), '_');
                    final classId = '${selectedBatchId!}_${selectedLevelId!}_${selectedTermId!}_$normalizedSection';

                    await ref.read(adminServiceProvider).createClass(
                          classId: classId,
                          batchId: selectedBatchId!,
                          levelId: selectedLevelId!,
                          termId: selectedTermId!,
                          sectionName: section,
                          assignedTeacherIds: const <String>[],
                        );

                    ref.invalidate(classesProvider);

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class created successfully.')),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteClass(BuildContext context, WidgetRef ref, String classId, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete "$label"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).deleteClass(classId);
              ref.invalidate(classesProvider);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ==================== 4. Students Tab ====================

class _StudentsTab extends ConsumerStatefulWidget {
  const _StudentsTab();

  @override
  ConsumerState<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<_StudentsTab> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final batches = ref.watch(batchesProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);
    final levels = ref.watch(levelsProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);
    final terms = ref.watch(termsProvider).maybeWhen(data: (v) => v, orElse: () => const <Map<String, dynamic>>[]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Management',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 16),
          classesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading classes: $e', style: GoogleFonts.sora(color: Colors.redAccent)),
            data: (classes) {
              if (classes.isEmpty) {
                return Text(
                  'No classes yet. Create classes from the Classes tab first.',
                  style: GoogleFonts.sora(color: AppTheme.textGray),
                );
              }
              return DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Select Class',
                  labelStyle: GoogleFonts.sora(color: AppTheme.textGray),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.textGray.withOpacity(0.4)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.studentAccent),
                  ),
                ),
                dropdownColor: AppTheme.cardColor,
                style: GoogleFonts.sora(color: Colors.white),
                items: classes.map((cls) {
                  return DropdownMenuItem<String>(
                    value: cls['id'] as String,
                    child: Text(
                      _buildClassDisplayName(cls, batches: batches, levels: levels, terms: terms),
                      style: GoogleFonts.sora(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedClassId = value),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_selectedClassId != null) ...[
            ElevatedButton.icon(
              onPressed: () => _showAssignStudentDialog(context, _selectedClassId!),
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('Assign Student to Class'),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) {
                final studentsAsync = ref.watch(studentsByClassProvider(_selectedClassId!));
                return studentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e', style: GoogleFonts.sora(color: Colors.redAccent)),
                  data: (students) {
                    if (students.isEmpty) {
                      return Text(
                        'No students in this class yet. Assign students using the button above.',
                        style: GoogleFonts.sora(color: AppTheme.textGray),
                      );
                    }
                    return Column(
                      children: students
                          .map((s) => _buildStudentTile(context, s, _selectedClassId!))
                          .toList(),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, Map<String, dynamic> student, String classId) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.studentAccent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.user, color: AppTheme.studentAccent, size: 20),
        ),
        title: Text(
          student['name'] ?? 'Unknown',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          student['email'] ?? '',
          style: GoogleFonts.sora(color: AppTheme.textGray, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.userMinus, color: Colors.redAccent),
          tooltip: 'Remove from class',
          onPressed: () => _confirmRemoveStudent(context, student, classId),
        ),
      ),
    );
  }

  void _confirmRemoveStudent(BuildContext context, Map<String, dynamic> student, String classId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove ${student['name'] ?? 'this student'} from this class?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(adminServiceProvider).removeStudentFromClass(
                    studentId: student['id'] as String,
                    classId: classId,
                  );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAssignStudentDialog(BuildContext context, String classId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateInner) {
            final allStudentsAsync = ref.watch(studentsProvider);
            final assignedAsync = ref.watch(studentsByClassProvider(classId));
            final assignedIds =
                assignedAsync.value?.map((s) => s['id'] as String).toSet() ?? <String>{};

            return AlertDialog(
              title: const Text('Assign Student to Class'),
              content: SizedBox(
                width: 420,
                child: allStudentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (students) {
                    final unassigned = students
                        .where((s) => !assignedIds.contains(s['id'] as String))
                        .toList();
                    if (unassigned.isEmpty) {
                      return Text(
                        'All registered students are already in this class.',
                        style: GoogleFonts.sora(color: AppTheme.textGray),
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: unassigned.map((student) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              student['name'] ?? 'Unknown',
                              style: GoogleFonts.sora(fontSize: 14),
                            ),
                            subtitle: Text(
                              student['email'] ?? '',
                              style: GoogleFonts.sora(color: AppTheme.textGray, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.userPlus, color: AppTheme.studentAccent),
                              onPressed: () async {
                                try {
                                  await ref.read(adminServiceProvider).assignStudentToClass(
                                        studentId: student['id'] as String,
                                        classId: classId,
                                      );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${student['name'] ?? 'Student'} assigned to class.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to assign student: $e'),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            );
          },
        );
      },
    );
  }
}

// ==================== 5. Analytics Tab ====================

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(teachersProvider).value;
    final students = ref.watch(studentsProvider).value;
    final classes = ref.watch(classesProvider).value;
    final batches = ref.watch(batchesProvider).value;
    final missionsCount = ref.watch(missionsCountProvider).value;

    String count(int? val) => val == null ? '…' : val.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Analytics',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildStatCard('Total Teachers', count(teachers?.length), LucideIcons.briefcase, AppTheme.teacherAccent),
          const SizedBox(height: 12),
          _buildStatCard('Total Students', count(students?.length), LucideIcons.users, AppTheme.studentAccent),
          const SizedBox(height: 12),
          _buildStatCard('Total Classes', count(classes?.length), LucideIcons.school, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildStatCard('Total Batches', count(batches?.length), LucideIcons.calendar, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildStatCard('Total Missions', count(missionsCount), LucideIcons.target, const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.sora(color: AppTheme.textGray, fontSize: 14),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpRulesTab extends ConsumerWidget {
  const _XpRulesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(xpSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (settings) {
        final attendancePresent = _toInt(settings['attendancePresentXp'], 10);
        final attendanceAbsent = _toInt(settings['attendanceAbsentPenalty'], 4);
        final assessment = Map<String, dynamic>.from(settings['assessmentBaseXp'] ?? {});
        final classPerformance = _toInt(assessment['class_performance'], 80);
        final ct = _toInt(assessment['ct'], 100);
        final mid = _toInt(assessment['mid'], 140);
        final finalExam = _toInt(assessment['final'], 180);
        final penaltyMultiplier = _toDouble(settings['performanceDropPenaltyMultiplier'], 1.0);
        final penaltyCap = _toInt(settings['performanceDropPenaltyCapPercent'], 70);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XP Rules Configuration',
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Teacher attendance and marks XP behavior will follow these rules.',
                style: GoogleFonts.sora(fontSize: 13, color: AppTheme.textGray),
              ),
              const SizedBox(height: 16),
              _buildConfigCard('Attendance Present XP', '$attendancePresent'),
              _buildConfigCard('Attendance Absent Penalty', '$attendanceAbsent'),
              _buildConfigCard('Class Performance Base XP', '$classPerformance'),
              _buildConfigCard('CT Base XP', '$ct'),
              _buildConfigCard('Mid Base XP', '$mid'),
              _buildConfigCard('Final Base XP', '$finalExam'),
              _buildConfigCard('Drop Penalty Multiplier', penaltyMultiplier.toStringAsFixed(2)),
              _buildConfigCard('Drop Penalty Cap (%)', '$penaltyCap'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditXpDialog(context, ref, settings),
                  icon: const Icon(LucideIcons.slidersHorizontal),
                  label: const Text('Edit XP Rules'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigCard(String label, String value) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          label,
          style: GoogleFonts.sora(color: Colors.white),
        ),
        trailing: Text(
          value,
          style: GoogleFonts.sora(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditXpDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
  ) async {
    final assessment = Map<String, dynamic>.from(settings['assessmentBaseXp'] ?? {});

    final presentCtrl = TextEditingController(text: _toInt(settings['attendancePresentXp'], 10).toString());
    final absentCtrl = TextEditingController(text: _toInt(settings['attendanceAbsentPenalty'], 4).toString());
    final perfCtrl = TextEditingController(text: _toInt(assessment['class_performance'], 80).toString());
    final ctCtrl = TextEditingController(text: _toInt(assessment['ct'], 100).toString());
    final midCtrl = TextEditingController(text: _toInt(assessment['mid'], 140).toString());
    final finalCtrl = TextEditingController(text: _toInt(assessment['final'], 180).toString());
    final multiplierCtrl = TextEditingController(
      text: _toDouble(settings['performanceDropPenaltyMultiplier'], 1.0).toStringAsFixed(2),
    );
    final capCtrl = TextEditingController(text: _toInt(settings['performanceDropPenaltyCapPercent'], 70).toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit XP Rules'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(presentCtrl, 'Attendance Present XP'),
              _numberField(absentCtrl, 'Attendance Absent Penalty'),
              _numberField(perfCtrl, 'Class Performance Base XP'),
              _numberField(ctCtrl, 'CT Base XP'),
              _numberField(midCtrl, 'Mid Base XP'),
              _numberField(finalCtrl, 'Final Base XP'),
              _numberField(multiplierCtrl, 'Drop Penalty Multiplier', decimal: true),
              _numberField(capCtrl, 'Drop Penalty Cap (%)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(adminServiceProvider);
              await service.updateXpSettings(
                attendancePresentXp: int.tryParse(presentCtrl.text.trim()) ?? 10,
                attendanceAbsentPenalty: int.tryParse(absentCtrl.text.trim()) ?? 4,
                assessmentBaseXp: {
                  'class_performance': int.tryParse(perfCtrl.text.trim()) ?? 80,
                  'ct': int.tryParse(ctCtrl.text.trim()) ?? 100,
                  'mid': int.tryParse(midCtrl.text.trim()) ?? 140,
                  'final': int.tryParse(finalCtrl.text.trim()) ?? 180,
                },
                performanceDropPenaltyMultiplier: double.tryParse(multiplierCtrl.text.trim()) ?? 1.0,
                performanceDropPenaltyCapPercent: int.tryParse(capCtrl.text.trim()) ?? 70,
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('XP rules updated successfully.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label, {bool decimal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  int _toInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  double _toDouble(Object? value, double fallback) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return fallback;
  }
}

String _buildClassDisplayName(
  Map<String, dynamic> classData, {
  required List<Map<String, dynamic>> batches,
  required List<Map<String, dynamic>> levels,
  required List<Map<String, dynamic>> terms,
}) {
  final batchId = classData['batchId'] as String?;
  final levelId = classData['levelId'] as String?;
  final termId = classData['termId'] as String?;
  final sectionName = (classData['sectionName'] ?? '').toString();

  final batch = batches.cast<Map<String, dynamic>?>().firstWhere(
        (b) => b?['id'] == batchId,
        orElse: () => null,
      );
  final level = levels.cast<Map<String, dynamic>?>().firstWhere(
        (l) => l?['id'] == levelId,
        orElse: () => null,
      );
  final term = terms.cast<Map<String, dynamic>?>().firstWhere(
        (t) => t?['id'] == termId,
        orElse: () => null,
      );

  final batchLabel = batch == null ? 'Batch ?' : 'Batch ${batch['year']}';
  final levelLabel = level == null ? 'L?' : 'L${level['levelNumber']}';
  final termLabel = term == null ? 'T?' : 'T${term['termNumber']}';
  final sectionLabel = sectionName.isEmpty ? '-' : sectionName;

  return '$batchLabel • $levelLabel • $termLabel • Sec $sectionLabel';
}

// ==================== Helper Widgets ====================

Widget _buildSection({
  required String title,
  required IconData icon,
  required Widget content,
  VoidCallback? onAdd,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: AppTheme.studentAccent),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              icon: const Icon(LucideIcons.plus),
              onPressed: onAdd,
            ),
        ],
      ),
      const SizedBox(height: 12),
      content,
    ],
  );
}

Widget _buildListTile({
  required String title,
  required String subtitle,
  VoidCallback? onDelete,
}) {
  return Card(
    color: AppTheme.cardColor,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(
        title,
        style: GoogleFonts.sora(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.sora(color: AppTheme.textGray),
      ),
      trailing: IconButton(
        icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
        onPressed: onDelete,
      ),
    ),
  );
}
