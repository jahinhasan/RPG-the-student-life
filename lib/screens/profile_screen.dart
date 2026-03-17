import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../routes.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';
import '../utils/level_calculator.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = [
      {'id': '1', 'name': 'First Victory', 'emoji': '🏆', 'unlocked': true},
      {'id': '2', 'name': 'Week Warrior', 'emoji': '⭐', 'unlocked': true},
      {'id': '3', 'name': 'Perfect Attendance', 'emoji': '🎯', 'unlocked': false},
      {'id': '4', 'name': 'Arena Master', 'emoji': '⚔️', 'unlocked': false},
    ];

    final unlockedWorlds = [
      {'id': '1', 'name': 'Classroom', 'emoji': '📚'},
      {'id': '2', 'name': 'Laboratory', 'emoji': '🔬'},
    ];

    final userStatsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile', style: GoogleFonts.poppins(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          )
        ],
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: userStatsAsync.when(
        data: (studentStats) {
          if (studentStats == null) {
            return const Center(
              child: Text('No profile data found', style: TextStyle(color: Colors.white70)),
            );
          }

          final xp = studentStats['xp'] as int? ?? 0;
          final level = studentStats['level'] as int? ?? LevelCalculator.getLevel(xp);
          final currentLevelBaseXp = LevelCalculator.getXPForLevel(level);
          final nextLevelXp = LevelCalculator.getXPForLevel(level + 1);
          final avatarEmoji = (studentStats['avatar'] ?? '👨‍🎓') as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF111827)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.studentAccent,
                        child: Text(avatarEmoji, style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (studentStats['name'] ?? 'Student') as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (studentStats['title'] ?? 'Novice Scholar') as String,
                        style: const TextStyle(color: AppTheme.teacherAccent, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF172554),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Lvl $level',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            children: [
                              const Text('Global Rank', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                              Text(
                                '#${studentStats['rank'] ?? 12}',
                                style: GoogleFonts.poppins(color: AppTheme.teacherAccent, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('XP Progress', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                                Text(
                                  '${xp - currentLevelBaseXp}/${nextLevelXp - currentLevelBaseXp}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: LevelCalculator.getLevelProgress(xp),
                                backgroundColor: const Color(0xFF374151),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.studentAccent),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Academic Performance', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildStatCard('GPA', '${studentStats['gpa'] ?? 3.8}'),
                          _buildStatCard('Attendance', '${studentStats['attendance'] ?? 95}%'),
                          _buildStatCard('CPA', '${studentStats['cpa'] ?? 3.5}'),
                          _buildStatCard('Battle Record', '${studentStats['wins'] ?? 15}W-${studentStats['losses'] ?? 4}L'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(LucideIcons.award, color: AppTheme.teacherAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Achievements', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Text(
                            '(${achievements.where((item) => item['unlocked'] == true).length}/${achievements.length})',
                            style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          final achievement = achievements[index];
                          final isUnlocked = achievement['unlocked'] == true;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: isUnlocked ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]) : null,
                              color: isUnlocked ? null : AppTheme.cardColor,
                              border: Border.all(color: isUnlocked ? Colors.transparent : const Color(0xFF1F2937)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  achievement['emoji']! as String,
                                  style: TextStyle(fontSize: 24, color: isUnlocked ? Colors.white : Colors.white38),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement['name']! as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9, color: isUnlocked ? Colors.white : AppTheme.textGray),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(LucideIcons.target, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text('Unlocked Worlds', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: unlockedWorlds.length,
                        itemBuilder: (context, index) {
                          final world = unlockedWorlds[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              border: Border.all(color: const Color(0xFF1F2937)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(world['emoji'] as String, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Text(world['name'] as String, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.avatarCustomization),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.studentAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Customize Avatar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppTheme.cardColor,
                            side: const BorderSide(color: Color(0xFF374151)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Edit Profile', style: GoogleFonts.poppins(color: Colors.white)),
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
          child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: const Color(0xFF1F2937)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }
}
