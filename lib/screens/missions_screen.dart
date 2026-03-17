import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/mission_service.dart';
import '../widgets/mission_details_sheet.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  String activeTab = 'daily';

  @override
  Widget build(BuildContext context) {
    final missionsAsync = ref.watch(missionsProvider);
    final locallyClaimed = ref.watch(locallyClaimedMissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Missions & Achievements', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: missionsAsync.when(
        data: (missions) {
          final dailyMissions = missions.where((m) => m['type'] == 'daily').toList();
          final weeklyMissions = missions.where((m) => m['type'] == 'weekly').toList();
          // For now, achievements are separate or can be another type
          final achievements = missions.where((m) => m['type'] == 'achievement').toList();

          return Column(
            children: [
              _buildTabs(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: activeTab == 'achievements'
                      ? _buildAchievements(achievements)
                        : _buildMissionsList(
                            activeTab == 'daily' ? dailyMissions : weeklyMissions,
                            locallyClaimed,
                          ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['daily', 'weekly', 'achievements'];
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgColor,
        border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => activeTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.studentAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tab == 'daily') const Icon(LucideIcons.clock, size: 16, color: AppTheme.textGray),
                    if (tab == 'daily') const SizedBox(width: 4),
                    Text(
                      tab[0].toUpperCase() + tab.substring(1),
                      style: GoogleFonts.poppins(
                        color: isActive ? AppTheme.studentAccent : AppTheme.textGray,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMissionsList(List<Map<String, dynamic>> missions, Set<String> locallyClaimed) {
    if (missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No $activeTab missions available', style: const TextStyle(color: AppTheme.textGray)),
        ),
      );
    }

    return Column(
      children: missions.map((mission) {
        final progress = (mission['prog'] ?? 0.0) as double;
        final missionId = mission['id'] as String?;
        final isCompleted = mission['done'] == true || (missionId != null && locallyClaimed.contains(missionId));
        final isClaimable = !isCompleted && progress >= 1.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showMissionDetailsSheet(context, mission),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                border: Border.all(color: isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF1F2937)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mission['title'] ?? 'Mission', 
                              style: GoogleFonts.poppins(
                                color: isCompleted ? AppTheme.textGray : Colors.white, 
                                fontSize: 16, 
                                fontWeight: FontWeight.w500,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              )
                            ),
                            const SizedBox(height: 4),
                            Text(mission['desc'] ?? '', style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(LucideIcons.user, size: 14, color: AppTheme.studentAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${mission['teacherName'] ?? 'Teacher'} • ${mission['courseCode'] ?? 'COURSE-101'}',
                                    style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 11),
                                  ),
                                ),
                                Text(
                                  'Tap for details',
                                  style: GoogleFonts.poppins(color: AppTheme.studentAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('+${mission['xp'] ?? 0}', 
                            style: GoogleFonts.poppins(
                              color: isCompleted ? AppTheme.textGray : AppTheme.teacherAccent, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                          const Text('XP', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF374151),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isCompleted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Text('Completed', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontWeight: FontWeight.w500)),
                      ],
                    )
                  else if (isClaimable)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final awarded = await ref.read(missionServiceProvider).completeMission(mission['id'], mission['xp'] as int);
                          ref.read(locallyClaimedMissionsProvider.notifier).markClaimed(mission['id'] as String);
                          ref.invalidate(missionsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(awarded ? 'Claimed ${mission['xp']} XP!' : 'Reward already claimed.')),
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
                  else
                    const Center(child: Text('In Progress...', style: TextStyle(color: AppTheme.textGray, fontSize: 13))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievements(List<Map<String, dynamic>> achievements) {
    if (achievements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No achievements unlocked yet', style: TextStyle(color: AppTheme.textGray)),
        ),
      );
    }

    return Column(
      children: achievements.map((achieve) {
        final unlocked = achieve['done'] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unlocked ? const Color(0x33F59E0B) : AppTheme.cardColor,
            border: Border.all(color: unlocked ? const Color(0x80F59E0B) : const Color(0xFF1F2937)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]) : null,
                  color: unlocked ? null : const Color(0xFF1F2937),
                ),
                child: Icon(LucideIcons.star, color: unlocked ? Colors.white : Colors.white38, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achieve['title'] ?? 'Achievement', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(achieve['desc'] ?? '', style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Reward: +${achieve['xp'] ?? 0} XP', style: const TextStyle(color: AppTheme.teacherAccent, fontSize: 13)),
                  ],
                ),
              ),
              if (unlocked) const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 28),
            ],
          ),
        );
      }).toList(),
    );
  }
}
