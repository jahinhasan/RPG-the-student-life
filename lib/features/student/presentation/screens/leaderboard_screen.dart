import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rpg_student_life/providers/auth_provider.dart';
import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String activeTab = 'class';

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Leaderboard', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: leaderboardAsync.when(
              data: (users) {
                final topThree = users.take(3).toList();
                final rest = users.skip(3).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (users.isNotEmpty) _buildPodium(topThree),
                      const SizedBox(height: 32),
                      _buildRestOfLeaderboard(rest, currentUser?.uid),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading leaderboard: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['class', 'department', 'university'];
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
                child: Text(
                  tab[0].toUpperCase() + tab.substring(1),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: isActive ? AppTheme.studentAccent : AppTheme.textGray,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (top.length >= 2) 
          _buildPodiumItem(top[1], 2, 100, const [Color(0xFF9CA3AF), Color(0xFF4B5563)], LucideIcons.medal),
        if (top.isNotEmpty)
          _buildPodiumItem(top[0], 1, 130, const [Color(0xFFF59E0B), Color(0xFFD97706)], LucideIcons.trophy),
        if (top.length >= 3)
          _buildPodiumItem(top[2], 3, 80, const [Color(0xFFB45309), Color(0xFF78350F)], LucideIcons.award),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double height, List<Color> colors, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: Icon(LucideIcons.user, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Icon(icon, color: Colors.white70, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    user['name'],
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Lvl ${user['level']}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  Text('${user['xp']} XP', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors[1],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRestOfLeaderboard(List<Map<String, dynamic>> rest, String? currentUid) {
    return Column(
      children: rest.map((user) {
        final isMe = user['uid'] == currentUid;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.studentAccent.withValues(alpha: 0.1) : AppTheme.cardColor,
            border: Border.all(color: isMe ? AppTheme.studentAccent.withValues(alpha: 0.5) : const Color(0xFF1F2937)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('#${user['rank']}', style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.teacherAccent,
                child: Icon(LucideIcons.user, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                    Text('${user['xp']} XP', style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Lvl ${user['level']}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
