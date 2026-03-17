import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/battle_service.dart';
import '../services/xp_service.dart';

class BattleArenaScreen extends ConsumerStatefulWidget {
  const BattleArenaScreen({super.key});

  @override
  ConsumerState<BattleArenaScreen> createState() => _BattleArenaScreenState();
}

class _BattleArenaScreenState extends ConsumerState<BattleArenaScreen> {
  late String battleState = 'lobby'; // lobby, battle, result
  late int currentQuestion = 0;
  late int playerScore = 0;
  late int opponentScore = 0;
  late int timeLeft = 30;
  
  late List<BattleQuestion> questions;
  BattleOpponent? opponent;
  late bool isLoading = true;
  late String? errorMessage;

  @override
  void initState() {
    super.initState();
    questions = [];
    opponent = null;
    isLoading = true;
    errorMessage = null;
    _initializeBattle();
  }

  Future<void> _initializeBattle() async {
    try {
      final battleService = ref.read(battleServiceProvider);
      
      final fetchedQuestions = await battleService.getBattleQuestions(limit: 5);
      final fetchedOpponent = await battleService.getRandomOpponent();

      if (mounted) {
        setState(() {
          questions = fetchedQuestions;
          opponent = fetchedOpponent;
          isLoading = false;
          
          if (questions.isEmpty) {
            errorMessage = 'Failed to load questions';
          } else if (opponent == null) {
            errorMessage = 'No opponents available';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading battle data: $e';
          isLoading = false;
        });
      }
    }
  }

  void _startBattle() {
    setState(() {
      battleState = 'battle';
      timeLeft = 30;
      currentQuestion = 0;
      playerScore = 0;
      opponentScore = 0;
    });
  }

  void _handleAnswer(int optionIndex) {
    if (questions.isEmpty) return;
    
    final isCorrect = optionIndex == questions[currentQuestion].correctIndex;
    
    setState(() {
      if (isCorrect) {
        playerScore += 100;
      } else {
        opponentScore += 100;
      }

      if (currentQuestion < questions.length - 1) {
        currentQuestion++;
        timeLeft = 30;
      } else {
        battleState = 'result';
        _updateBattleResult();
      }
    });
  }

  Future<void> _updateBattleResult() async {
    try {
      final battleService = ref.read(battleServiceProvider);
      final isWin = playerScore > opponentScore;
      final xpReward = battleService.calculateXPReward(won: isWin, difficulty: 2);
      
      await battleService.updateBattleStats(won: isWin, xpEarned: xpReward);
    } catch (e) {
      debugPrint('Error updating battle result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Battle Arena', style: GoogleFonts.poppins(fontSize: 20)),
          backgroundColor: AppTheme.cardColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Battle Arena', style: GoogleFonts.poppins(fontSize: 20)),
          backgroundColor: AppTheme.cardColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(errorMessage!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                  child: Text('Go Back', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Battle Arena', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (battleState == 'lobby') return _buildLobby();
    if (battleState == 'battle') return _buildBattle();
    return _buildResult();
  }

  Widget _buildLobby() {
    final playerStatsAsync = ref.watch(userStatsProvider);

    return playerStatsAsync.when(
      data: (playerStats) {
        if (opponent == null) {
          return Center(
            child: Text(
              'No opponents available',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x33EF4444), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0x4DEF4444)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Battle', style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.normal)),
                    const SizedBox(height: 8),
                    const Text('Compete against other students in real-time quiz battles', style: TextStyle(color: AppTheme.textGray)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.studentAccent,
                        child: Text(
                          playerStats?['avatar'] ?? '👨‍🎓',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(playerStats?['name'] ?? 'You', style: GoogleFonts.poppins(color: Colors.white)),
                      Text('Level ${playerStats?['level'] ?? 1}', style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                    ],
                  ),
                  Text('VS', style: GoogleFonts.poppins(fontSize: 32, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.teacherAccent,
                        child: Text(
                          opponent?.avatar ?? '👤',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(opponent?.name ?? 'Opponent', style: GoogleFonts.poppins(color: Colors.white)),
                      Text('Level ${opponent?.level ?? 1}', style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Power-ups', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildPowerup(LucideIcons.zap, const Color(0xFFF59E0B), 'Double XP')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPowerup(LucideIcons.shield, const Color(0xFF3B82F6), 'Shield')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPowerup(LucideIcons.clock, const Color(0xFF10B981), 'Time Freeze')),
                    ],
                  )
                ],
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startBattle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Start Battle', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error: $err', style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }

  Widget _buildPowerup(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: const Color(0xFF1F2937)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBattle() {
    if (questions.isEmpty) {
      return Center(
        child: Text('No questions loaded', style: GoogleFonts.poppins(color: Colors.white)),
      );
    }

    final question = questions[currentQuestion];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.studentAccent,
                    child: Text('👤', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('You', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('$playerScore', style: GoogleFonts.poppins(color: const Color(0xFF3B82F6), fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Opponent', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('$opponentScore', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.teacherAccent,
                    child: Text(opponent?.avatar ?? '👤', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(LucideIcons.clock, color: Color(0xFFEF4444), size: 20),
              Text('${timeLeft}s', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: timeLeft / 30,
              backgroundColor: const Color(0xFF1F2937),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: Border.all(color: const Color(0xFF1F2937)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question ${currentQuestion + 1}/${questions.length}', style: const TextStyle(color: AppTheme.textGray, fontSize: 14)),
                const SizedBox(height: 8),
                Text(question.question, style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.normal)),
                const SizedBox(height: 24),
                
                ...List.generate(question.options.length, (index) {
                  final letter = String.fromCharCode(65 + index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _handleAnswer(index),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.bgColor,
                          side: const BorderSide(color: Color(0xFF374151)),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.centerLeft,
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                            children: [
                              TextSpan(text: '$letter. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: question.options[index]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final isWin = playerScore > opponentScore;
    final battleService = ref.read(battleServiceProvider);
    final xpReward = battleService.calculateXPReward(won: isWin, difficulty: 2);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWin ? '🏆' : '💔',
            style: const TextStyle(fontSize: 96),
          ),
          const SizedBox(height: 16),
          Text(
            isWin ? 'Victory!' : 'Defeat',
            style: GoogleFonts.poppins(
              fontSize: 32, 
              color: isWin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.normal
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWin ? 'You defeated ${opponent?.name ?? "opponent"}' : 'Better luck next time!',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          if (isWin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x3310B981), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0x4D10B981)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text('+$xpReward XP', style: GoogleFonts.poppins(fontSize: 36, color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Great job! Keep playing to level up', style: TextStyle(color: AppTheme.textGray, fontSize: 14)),
                ],
              ),
            ),
            
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  battleState = 'lobby';
                  currentQuestion = 0;
                  playerScore = 0;
                  opponentScore = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.studentAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Battle Again', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
