import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:rpg_student_life/routes.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final miniGames = [
      {'id': 'quiz-battle', 'name': 'Quiz Battle', 'desc': 'Head-to-head trivia showdown', 'icon': LucideIcons.brain, 'colors': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)], 'players': '1v1', 'xp': 150, 'diff': 'Medium', 'diffColor': const Color(0xFFF59E0B), 'route': AppRoutes.quizBattleGame},
      {'id': 'speed-math', 'name': 'Speed Math', 'desc': 'Race to solve math problems', 'icon': LucideIcons.calculator, 'colors': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], 'players': '1v1', 'xp': 100, 'diff': 'Easy', 'diffColor': const Color(0xFF10B981), 'route': AppRoutes.speedMathGame},
      {'id': 'word-scramble', 'name': 'Word Scramble', 'desc': 'Unscramble academic terms', 'icon': LucideIcons.bookOpen, 'colors': [const Color(0xFF10B981), const Color(0xFF059669)], 'players': '1v1', 'xp': 120, 'diff': 'Easy', 'diffColor': const Color(0xFF10B981), 'route': AppRoutes.wordScrambleGame},
      {'id': 'memory-match', 'name': 'Memory Match', 'desc': 'Match academic concepts', 'icon': LucideIcons.layoutGrid, 'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)], 'players': '1v1', 'xp': 130, 'diff': 'Medium', 'diffColor': const Color(0xFFF59E0B), 'route': AppRoutes.memoryMatchGame},
      {'id': 'tic-tac-trivia', 'name': 'Tic-Tac-Trivia', 'desc': 'Tic-tac-toe with quiz questions', 'icon': LucideIcons.layoutGrid, 'colors': [const Color(0xFFEF4444), const Color(0xFFB91C1C)], 'players': '1v1', 'xp': 140, 'diff': 'Medium', 'diffColor': const Color(0xFFF59E0B), 'route': AppRoutes.ticTacTriviaGame},
      {'id': 'team-raid', 'name': 'Team Raid', 'desc': 'Cooperative challenge mode', 'icon': LucideIcons.users, 'colors': [const Color(0xFFEC4899), const Color(0xFFBE185D)], 'players': '4v4', 'xp': 300, 'diff': 'Hard', 'diffColor': const Color(0xFFEF4444), 'route': AppRoutes.teamRaidGame},
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mini Games', style: GoogleFonts.poppins(fontSize: 20)),
            const Text('Challenge friends & earn XP', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
          ],
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x338B5CF6), Colors.transparent],
                ),
                border: Border.all(color: const Color(0x4D8B5CF6)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Games Played Today', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('12', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Win Rate', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('67%', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 24)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('XP Earned', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('890', style: GoogleFonts.poppins(color: const Color(0xFFF59E0B), fontSize: 24)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: miniGames.length,
        itemBuilder: (context, index) {
          final game = miniGames[index];
          final colors = game['colors'] as List<Color>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, game['route'] as String),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(game['icon'] as IconData, size: 120, color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(game['icon'] as IconData, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(game['name'] as String, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.normal)),
                                  Text(game['desc'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(game['players'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Text(game['diff'] as String, style: TextStyle(color: game['diffColor'] as Color, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.zap, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('+${game['xp']}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
