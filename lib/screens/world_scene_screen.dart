import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/xp_service.dart';
import '../services/mission_service.dart';
import '../theme/app_theme.dart';

class WorldSceneScreen extends ConsumerStatefulWidget {
  const WorldSceneScreen({super.key});

  @override
  ConsumerState<WorldSceneScreen> createState() => _WorldSceneScreenState();
}

class _WorldSceneScreenState extends ConsumerState<WorldSceneScreen> {
  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final worldName = (arguments?['name'] ?? 'World Zone') as String;
    final worldLevel = arguments?['level']?.toString() ?? '1';
    final userStatsAsync = ref.watch(userStatsProvider);
    final missionsAsync = ref.watch(missionsProvider);
    final locallyClaimed = ref.watch(locallyClaimedMissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          worldName,
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
      ),
      body: userStatsAsync.when(
        data: (stats) {
          final playerName = (stats?['name'] ?? 'Student') as String;

          return missionsAsync.when(
            data: (missions) {
              final objectives = missions
                  .where((mission) => (mission['type'] ?? '') != 'achievement')
                  .toList();
              final completedCount = objectives.where((objective) {
                final id = objective['id'] as String?;
                return objective['done'] == true || (id != null && locallyClaimed.contains(id));
              }).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1E3A8A),
                            Color(0xFF111827),
                            Color(0xFF0B1120),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF1F2937)),
                        ),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.studentAccent,
                            child: Icon(
                              LucideIcons.user,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            playerName,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFF374151)),
                            ),
                            child: Text(
                              'Exploring $worldName • Level $worldLevel Zone',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.award,
                                color: AppTheme.teacherAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Objectives',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (objectives.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF1F2937)),
                              ),
                              child: Text(
                                'No objectives assigned yet for your account.',
                                style: GoogleFonts.poppins(color: AppTheme.textGray),
                              ),
                            ),
                          ...objectives.map((objective) {
                            final missionId = objective['id'] as String?;
                            final progressValue = objective['prog'];
                            final progress = progressValue is num ? progressValue.toDouble() : 0.0;
                            final completed = objective['done'] == true || (missionId != null && locallyClaimed.contains(missionId));
                            final canClaim = !completed && progress >= 1.0 && missionId != null;
                            final xpValue = objective['xp'];
                            final xp = xpValue is num ? xpValue.toInt() : 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (objective['title'] ?? 'Objective') as String,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Reward: +$xp XP',
                                            style: const TextStyle(
                                              color: AppTheme.teacherAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if ((objective['desc'] as String?)?.isNotEmpty == true)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                objective['desc'] as String,
                                                style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: canClaim
                                          ? () async {
                                              final awarded = await ref.read(missionServiceProvider).completeMission(missionId, xp);
                                              ref.read(locallyClaimedMissionsProvider.notifier).markClaimed(missionId);
                                              ref.invalidate(missionsProvider);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      awarded ? 'Claimed $xp XP!' : 'Reward already claimed.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                      icon: Icon(
                                        completed
                                            ? LucideIcons.checkCircle
                                            : LucideIcons.check,
                                        size: 16,
                                      ),
                                      label: Text(completed
                                          ? 'Done'
                                          : canClaim
                                              ? 'Claim'
                                              : 'Progress'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: completed
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF10B981),
                                        disabledBackgroundColor: const Color(0xFF374151),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x223B82F6), Colors.transparent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x553B82F6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Zone Progress',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: objectives.isEmpty ? 0 : completedCount / objectives.length,
                                    minHeight: 10,
                                    backgroundColor: const Color(0xFF1F2937),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppTheme.studentAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$completedCount/${objectives.length} objectives complete',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
