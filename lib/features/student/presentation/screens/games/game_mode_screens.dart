import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class _GameModeConfig {
  const _GameModeConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.reward,
    required this.metricLabel,
    required this.tasks,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final int reward;
  final String metricLabel;
  final List<String> tasks;
}

class _MiniGameModeScreen extends ConsumerStatefulWidget {
  const _MiniGameModeScreen({required this.config});

  final _GameModeConfig config;

  @override
  ConsumerState<_MiniGameModeScreen> createState() => _MiniGameModeScreenState();
}

class _MiniGameModeScreenState extends ConsumerState<_MiniGameModeScreen> {
  int _completedTasks = 0;
  bool _rewardClaimed = false;

  Future<void> _completeTask() async {
    if (_completedTasks >= widget.config.tasks.length) {
      return;
    }

    setState(() {
      _completedTasks += 1;
    });
  }

  Future<void> _claimReward() async {
    if (_rewardClaimed || _completedTasks < widget.config.tasks.length) {
      return;
    }

    await ref.read(xpServiceProvider).addXP(widget.config.reward);

    if (!mounted) {
      return;
    }

    setState(() {
      _rewardClaimed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.config.title} complete. +${widget.config.reward} XP awarded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.config.tasks.isEmpty ? 0.0 : _completedTasks / widget.config.tasks.length;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.config.title, style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: widget.config.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(widget.config.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 18),
                  Text(widget.config.title, style: GoogleFonts.poppins(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(widget.config.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildHeaderStat(widget.config.metricLabel, '$_completedTasks/${widget.config.tasks.length}'),
                      const SizedBox(width: 12),
                      _buildHeaderStat('Reward', '+${widget.config.reward} XP'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Challenges', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...List.generate(widget.config.tasks.length, (index) {
              final isDone = index < _completedTasks;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone ? LucideIcons.checkCircle : LucideIcons.circle,
                        color: isDone ? const Color(0xFF10B981) : AppTheme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.config.tasks[index],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF1F2937),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.config.colors.first),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).round()}% complete', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.config.colors.first, widget.config.colors.last],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.config.colors.first.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _completedTasks < widget.config.tasks.length ? _completeTask : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.play, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _completedTasks < widget.config.tasks.length ? 'Complete Next Challenge' : 'All Challenges Completed',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.config.colors.first.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_completedTasks == widget.config.tasks.length && !_rewardClaimed) ? _claimReward : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.zap, color: widget.config.colors.first, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _rewardClaimed ? 'Reward Claimed ✓' : 'Claim XP Reward',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class QuizBattleGameScreen extends StatelessWidget {
  const QuizBattleGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MiniGameModeScreen(
      config: _GameModeConfig(
        title: 'Quiz Battle',
        subtitle: 'Head-to-head trivia showdown with fast academic challenges.',
        icon: LucideIcons.brain,
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        reward: 150,
        metricLabel: 'Rounds',
        tasks: ['Answer algorithms question', 'Beat opponent streak', 'Finish final trivia round'],
      ),
    );
  }
}

class SpeedMathGameScreen extends StatelessWidget {
  const SpeedMathGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MiniGameModeScreen(
      config: _GameModeConfig(
        title: 'Speed Math',
        subtitle: 'Solve quick-fire calculations before the timer runs out.',
        icon: LucideIcons.calculator,
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        reward: 100,
        metricLabel: 'Problems',
        tasks: ['Solve warm-up equation', 'Complete speed round', 'Finish streak challenge'],
      ),
    );
  }
}

class WordScrambleGameScreen extends StatelessWidget {
  const WordScrambleGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MiniGameModeScreen(
      config: _GameModeConfig(
        title: 'Word Scramble',
        subtitle: 'Unscramble academic terms and course keywords.',
        icon: LucideIcons.bookOpen,
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        reward: 120,
        metricLabel: 'Words',
        tasks: ['Unscramble first term', 'Complete bonus word', 'Solve final keyword'],
      ),
    );
  }
}

class MemoryMatchGameScreen extends StatelessWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MiniGameModeScreen(
      config: _GameModeConfig(
        title: 'Memory Match',
        subtitle: 'Pair related concepts and sharpen recall speed.',
        icon: LucideIcons.layoutGrid,
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        reward: 130,
        metricLabel: 'Pairs',
        tasks: ['Match first concept pair', 'Clear second board', 'Finish memory sprint'],
      ),
    );
  }
}

class TicTacTriviaGameScreen extends StatelessWidget {
  const TicTacTriviaGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MiniGameModeScreen(
      config: _GameModeConfig(
        title: 'Tic-Tac-Trivia',
        subtitle: 'Claim the board by answering trivia in each tile.',
        icon: LucideIcons.layoutGrid,
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
        reward: 140,
        metricLabel: 'Tiles',
        tasks: ['Win opening tile', 'Block opponent move', 'Complete winning row'],
      ),
    );
  }
}

class TeamRaidGameScreen extends StatelessWidget {
  const TeamRaidGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MiniGameModeScreen(
      config: _GameModeConfig(
        title: 'Team Raid',
        subtitle: 'Coordinate with allies to clear the cooperative raid.',
        icon: LucideIcons.users,
        colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
        reward: 300,
        metricLabel: 'Stages',
        tasks: ['Clear raid entrance', 'Secure team checkpoint', 'Defeat final boss'],
      ),
    );
  }
}