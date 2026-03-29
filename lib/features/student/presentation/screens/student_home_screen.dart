import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpg_student_life/theme/app_theme.dart';
import 'package:rpg_student_life/routes.dart';
import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/services/mission_service.dart';
import 'package:rpg_student_life/services/notifications_service.dart';
import 'package:rpg_student_life/services/admin_service.dart';
import 'package:rpg_student_life/utils/level_calculator.dart';
import 'package:rpg_student_life/utils/role_ability.dart';
import 'package:rpg_student_life/widgets/mission_details_sheet.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: userStats.when(
          data: (stats) {
            if (stats == null) return const Center(child: CircularProgressIndicator());
            
            final int xp = (stats['xp'] ?? 0) as int;
            final int level = LevelCalculator.getLevel(xp);
            final double progress = LevelCalculator.getLevelProgress(xp);
            final String name = (stats['name'] ?? 'Student') as String;
            final String title = (stats['title'] ?? 'Student').toString();
            final int rank = (stats['rank'] is num) ? (stats['rank'] as num).toInt() : 0;
            final classIds = List<String>.from(stats['classIds'] ?? const <String>[]);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, name, xp, level, progress, title, rank),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      _buildHeroSection(context, level, title, stats),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          'Daily Missions',
                          actionText: 'View All',
                          onActionTap: () {
                            debugPrint('[HOME] "View All" button tapped - navigating to /missions');
                            Navigator.pushNamed(context, AppRoutes.missions);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMissions(context, ref),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Academic Stats'),
                        const SizedBox(height: 16),
                        _buildAcademicStats(context, stats),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Role Ability'),
                        const SizedBox(height: 16),
                        _buildRoleAbilityCard(stats),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Game Center'),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Teacher Updates'),
                        const SizedBox(height: 16),
                        _buildTeacherUpdates(ref, classIds),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    int xp,
    int level,
    double progress,
    String title,
    int rank,
  ) {
    int nextLevelXp = LevelCalculator.getXPForLevel(level + 1);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                ),
                child: Text('Lvl $level', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text(
                          rank > 0 ? 'Rank #$rank' : 'Rank N/A',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGray),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, color: AppTheme.teacherAccent, size: 6),
                        const SizedBox(width: 8),
                        Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.teacherAccent)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  debugPrint('[HOME] Bell icon tapped - navigating to /notifications');
                  Navigator.pushNamed(context, '/notifications');
                },
                icon: Stack(
                  children: [
                    const Icon(LucideIcons.bell, color: AppTheme.textGray),
                    Consumer(
                      builder: (context, ref, _) {
                        final unreadCount = ref.watch(unreadNotificationCountProvider);
                        if (unreadCount > 0) {
                          return Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppTheme.studentAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: () {
                debugPrint('[HOME] Settings icon tapped - navigating to /settings');
                Navigator.pushNamed(context, '/settings');
              }, icon: const Icon(LucideIcons.settings, color: AppTheme.textGray)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1F2937),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.studentAccent),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$xp / $nextLevelXp XP', style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, int level, String title, Map<String, dynamic> stats) {
    final selectedBadge = (stats['selectedBadge'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        debugPrint('[HOME] Level hero section tapped - navigating to /profile');
        Navigator.pushNamed(context, AppRoutes.profile);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF111827)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.studentAccent,
              child: Icon(LucideIcons.user, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.sparkles, color: AppTheme.teacherAccent, size: 16),
                  const SizedBox(width: 8),
                  Text('Next: Master Scholar (Level ${((level / 5).floor() + 1) * 5})', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            if (selectedBadge.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Badge: $selectedBadge',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGray),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
        if (actionText != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(actionText, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.studentAccent)),
            ),
          ),
      ],
    );
  }

  Widget _buildMissions(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionsProvider);
    final locallyClaimed = ref.watch(locallyClaimedMissionsProvider);

    return missionsAsync.when(
      data: (missions) {
        final availableMissions = missions.where((mission) {
          final missionId = mission['id'] as String?;
          final isDaily = (mission['type'] ?? 'daily') == 'daily';
          return isDaily && mission['done'] != true && (missionId == null || !locallyClaimed.contains(missionId));
        }).toList();

        debugPrint(
          'Home missions visible: ${availableMissions.map((mission) => mission['id']).join(', ')}',
        );

        if (availableMissions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 28),
                const SizedBox(height: 10),
                Text(
                  'All visible daily missions are claimed.',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Open Missions to check weekly tasks and achievements.',
                  style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Only show top 2 on home screen
        final topMissions = availableMissions.take(2).toList();

        return Column(
          children: topMissions.map((m) {
            final bool isDone = m['done'] ?? false;
            final double prog = (m['prog'] ?? 0.0) as double;
            
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  debugPrint('[HOME] Mission card tapped: ${m['id']} - showing details sheet');
                  showMissionDetailsSheet(context, m);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF1F2937)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(m['title'] ?? 'Mission', 
                              style: GoogleFonts.poppins(
                                color: isDone ? AppTheme.textGray : Colors.white, 
                                fontWeight: FontWeight.w500,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              )
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('+${m['xp'] ?? 0} XP', 
                            style: GoogleFonts.poppins(
                              color: isDone ? AppTheme.textGray : AppTheme.teacherAccent, 
                              fontWeight: FontWeight.w600
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(m['desc'] ?? '', style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(LucideIcons.user, size: 14, color: AppTheme.studentAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${m['teacherName'] ?? '-'} • ${m['courseCode'] ?? '-'}',
                              style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 11),
                            ),
                          ),
                          Text(
                            'Tap for details',
                            style: GoogleFonts.poppins(color: AppTheme.studentAccent, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isDone)
                        Row(
                          children: [
                            const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 8),
                            Text('Completed', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: prog,
                            backgroundColor: const Color(0xFF374151),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            minHeight: 6,
                          ),
                        ),
                        if (prog >= 1.0) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                 debugPrint('[HOME] "Claim Reward" button tapped for mission=${m['id']}');
                                 final awarded = await ref.read(missionServiceProvider).completeMission(m['id'], m['xp'] as int);
                                 ref.read(locallyClaimedMissionsProvider.notifier).markClaimed(m['id'] as String);
                                 debugPrint('[HOME] Claim completed: mission=${m['id']} awarded=$awarded');
                                 ref.invalidate(missionsProvider);
                                 if (context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text(awarded ? 'Claimed ${m['xp']} XP!' : 'Reward already claimed.'))
                                   );
                                 }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Claim Reward', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            ),
                          )
                        ]
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildAcademicStats(BuildContext context, Map<String, dynamic> statsData) {
    final gpa = (statsData['gpa'] is num) ? (statsData['gpa'] as num).toDouble() : 0.0;
    final attendance = (statsData['attendance'] is num) ? (statsData['attendance'] as num).toDouble() : 0.0;
    final studyHours = (statsData['studyHours'] is num) ? (statsData['studyHours'] as num).toDouble() : 0.0;
    final wins = (statsData['wins'] is num) ? (statsData['wins'] as num).toDouble() : 0.0;
    final losses = (statsData['losses'] is num) ? (statsData['losses'] as num).toDouble() : 0.0;

    final stats = [
      {
        'label': 'GPA',
        'val': gpa,
        'max': 4.0,
        'icon': LucideIcons.bookOpen,
        'color': const Color(0xFF667EEA),
        'colors': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        'detail': 'Current GPA: ${gpa.toStringAsFixed(2)}',
        'unit': '/4.0'
      },
      {
        'label': 'Attendance',
        'val': attendance,
        'max': 100.0,
        'icon': LucideIcons.calendar,
        'color': const Color(0xFFF5576C),
        'colors': [const Color(0xFFF093FB), const Color(0xFFF5576C)],
        'detail': 'Attendance: ${attendance.toStringAsFixed(0)}%',
        'unit': '%'
      },
      {
        'label': 'Study Hours',
        'val': studyHours,
        'max': 20.0,
        'icon': LucideIcons.target,
        'color': const Color(0xFF00F2FE),
        'colors': [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
        'detail': 'Weekly study hours: ${studyHours.toStringAsFixed(1)}',
        'unit': '/20'
      },
      {
        'label': 'Battle W/L',
        'val': wins,
        'max': wins + losses == 0 ? 1.0 : wins + losses,
        'icon': LucideIcons.sword,
        'color': const Color(0xFFFA709A),
        'colors': [const Color(0xFFFA709A), const Color(0xFFFECE34)],
        'detail': 'Wins: ${wins.toStringAsFixed(0)}\nLosses: ${losses.toStringAsFixed(0)}',
        'unit': 'W'
      },
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: stats.map((s) {
        final colors = s['colors'] as List<Color>;
        final progress = (s['val'] as num) / (s['max'] as num);
        
        return GestureDetector(
          onTap: () {
            debugPrint('[HOME] Academic stat tapped: ${s['label']}');
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.bgColor,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (BuildContext ctx) => _buildStatDetailSheet(ctx, s as Map<String, dynamic>),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative background elements
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -10,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          s['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      // Center: Value and progress ring
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                (s['val'] as num).toStringAsFixed(s['label'] == 'Attendance' || s['label'] == 'Battle W/L' ? 0 : 1),
                                style: GoogleFonts.poppins(
                                  fontSize: 38,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 0.9,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s['unit'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Circular progress indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                            ),
                          ),
                        ],
                      ),

                      // Bottom: Label
                      Text(
                        s['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatDetailSheet(BuildContext context, Map<String, dynamic> stat) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat['label']!, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('${(stat['val'] as num).toStringAsFixed(stat['label'] == 'Attendance' ? 0 : 1)} ${stat['unit'] as String}', style: GoogleFonts.poppins(fontSize: 18, color: stat['color'] as Color, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (stat['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (stat['color'] as Color).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGray)),
                const SizedBox(height: 8),
                Text(stat['detail'] as String, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, height: 1.8)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: stat['color'] as Color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Close', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Battle Arena', 'icon': LucideIcons.sword, 'c1': const Color(0xFFEF4444), 'c2': const Color(0xFFB91C1C), 'accent': const Color(0xFFEF4444), 'route': AppRoutes.battleArena},
      {'label': 'RPG World', 'icon': LucideIcons.globe, 'c1': const Color(0xFF10B981), 'c2': const Color(0xFF059669), 'accent': const Color(0xFF10B981), 'route': AppRoutes.worldMap},
      {'label': 'Quiz Battle', 'icon': LucideIcons.brainCircuit, 'c1': const Color(0xFF8B5CF6), 'c2': const Color(0xFF6D28D9), 'accent': const Color(0xFF8B5CF6), 'route': AppRoutes.quizBattleGame},
      {'label': 'Survival Arena', 'icon': LucideIcons.shield, 'c1': const Color(0xFFF59E0B), 'c2': const Color(0xFFD97706), 'accent': const Color(0xFFF59E0B), 'route': AppRoutes.survivalArena},
      {'label': 'Unity Launch', 'icon': LucideIcons.rocket, 'c1': const Color(0xFF06B6D4), 'c2': const Color(0xFF0E7490), 'accent': const Color(0xFF06B6D4), 'route': AppRoutes.unityBridge},
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: actions.map((act) => GestureDetector(
        onTap: () {
          debugPrint('[HOME] Quick action tapped: ${act['label']} - navigating to ${act['route']}');
          Navigator.pushNamed(context, act['route'] as String);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                (act['c1'] as Color).withOpacity(0.15),
                (act['c2'] as Color).withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: (act['accent'] as Color).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (act['accent'] as Color).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background glow effect
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (act['accent'] as Color).withOpacity(0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (act['accent'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            act['icon'] as IconData,
                            color: act['accent'] as Color,
                            size: 24,
                          ),
                        ),
                        if (act['label'] == 'Battle Arena')
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(LucideIcons.zap, size: 14, color: Colors.red.shade400),
                          )
                        else if (act['label'] == 'Quiz Battle')
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(LucideIcons.sparkles, size: 14, color: Colors.purple.shade300),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (act['accent'] as Color).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TAP TO ENTER',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: act['accent'] as Color,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRoleAbilityCard(Map<String, dynamic> stats) {
    final ability = RoleAbilitySystem.forPlaystyle((stats['playstyle'] ?? 'scholar').toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.studentAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.sparkles, color: AppTheme.studentAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ability.playstyle} Ability: ${ability.ability}',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  ability.description,
                  style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherUpdates(WidgetRef ref, List<String> classIds) {
    final notifications = ref.watch(notificationsProvider);

    if (classIds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Text(
          'No class assigned yet. Once teacher assigns class quiz/announcement, you will see updates here.',
          style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
        ),
      );
    }

    final stream = ref.read(adminServiceProvider).streamStudentClassQuizzes(classIds);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Map<String, dynamic>>[];
        final announcementItems = notifications.take(2).toList();

        if (items.isEmpty && announcementItems.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Text(
              'No active quizzes yet.',
              style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
            ),
          );
        }

        return Column(
          children: [
            ...announcementItems.map((notice) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice.message,
                      style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.timestamp,
                      style: GoogleFonts.poppins(color: AppTheme.studentAccent, fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
            ...items.take(3).map((quiz) {
              return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Quiz: ${quiz['title'] ?? '-'}',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${quiz['description'] ?? ''}',
                    style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${quiz['type'] ?? 'quiz'} • ${quiz['rewardXp'] ?? 0} XP • ${quiz['timeLimitMinutes'] ?? 0} min',
                    style: GoogleFonts.poppins(color: AppTheme.studentAccent, fontSize: 11),
                  ),
                ],
              ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppTheme.cardColor,
      selectedItemColor: AppTheme.studentAccent,
      unselectedItemColor: AppTheme.textGray,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        debugPrint('[HOME] Bottom nav tapped: index=$index');
        if (index == 0) {
          debugPrint('[HOME] Home tab tapped (already on home)');
        }
        if (index == 1) {
          debugPrint('[HOME] Explore tab tapped - navigating to /world-map');
          Navigator.pushNamed(context, AppRoutes.worldMap);
        }
        if (index == 2) {
          debugPrint('[HOME] Stats tab tapped - navigating to /leaderboard');
          Navigator.pushNamed(context, AppRoutes.leaderboard);
        }
        if (index == 3) {
          debugPrint('[HOME] Profile tab tapped - navigating to /profile');
          Navigator.pushNamed(context, AppRoutes.profile);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.compass), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.award), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
      ],
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.14159 / 180, // Start from top
      (360 * progress) * 3.14159 / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
