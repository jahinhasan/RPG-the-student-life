import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class AIMentorScreen extends ConsumerStatefulWidget {
  const AIMentorScreen({super.key});

  @override
  ConsumerState<AIMentorScreen> createState() => _AIMentorScreenState();
}

class _AIMentorScreenState extends ConsumerState<AIMentorScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final suggestions = [
    {'icon': LucideIcons.trendingUp, 'text': 'Improve Attendance', 'colors': [const Color(0xFF10B981), const Color(0xFF059669)]},
    {'icon': LucideIcons.alertCircle, 'text': 'Focus on Final Exam', 'colors': [const Color(0xFFEF4444), const Color(0xFFB91C1C)]},
    {'icon': LucideIcons.brain, 'text': 'Start Research', 'colors': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]},
  ];

  final List<Map<String, String>> messages = [
    {
      'role': 'ai',
      'message': 'Hello! I\'m your AI Mentor. I\'ve analyzed your progress and noticed your attendance has dropped to 92%. Would you like tips to improve?'
    },
    {
      'role': 'user', 
      'message': 'Yes, please help me improve!'
    },
    {
      'role': 'ai', 
      'message': 'Great! Here are personalized strategies:\n\n1. Set daily reminders 15 minutes before class\n2. Join study groups to stay accountable\n3. Review your schedule every Sunday\n\nCompleting these will earn you +150 XP!'
    },
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final userStats = ref.read(userStatsProvider).value;
    
    setState(() {
      messages.add({'role': 'user', 'message': text});
      _msgCtrl.clear();
    });
    
    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'ai',
          'message': _buildMentorReply(text, userStats),
        });
      });
      _scrollToBottom();
    });
  }

  String _buildMentorReply(String prompt, Map<String, dynamic>? userStats) {
    final lowerPrompt = prompt.toLowerCase();
    final attendance = userStats?['attendance'] ?? 95;
    final gpa = userStats?['gpa'] ?? 3.8;
    final level = userStats?['level'] ?? 1;
    final wins = userStats?['wins'] ?? 0;

    if (lowerPrompt.contains('attendance')) {
      return 'Your attendance is currently $attendance%. To improve it, set a reminder before each class, prepare your bag the night before, and aim for a full week streak. Reaching 95%+ will keep your academic momentum strong.';
    }

    if (lowerPrompt.contains('gpa') || lowerPrompt.contains('grade') || lowerPrompt.contains('exam')) {
      return 'Your current GPA trend is $gpa. Focus on the next two highest-credit courses first, block daily revision time, and finish pending assignments before starting new topics. That will give you the best GPA lift with the least wasted effort.';
    }

    if (lowerPrompt.contains('battle') || lowerPrompt.contains('game') || lowerPrompt.contains('xp')) {
      return 'You are level $level with $wins recorded wins. The fastest XP path right now is: complete daily missions, clear a world objective, then finish one mini-game reward cycle. That gives you consistent progress without waiting on competitive matches.';
    }

    return 'Based on your current profile, I would focus on three things next: protect your attendance, finish the nearest mission reward, and use mini-games or world objectives for fast XP gains. If you want, ask about attendance, GPA, exams, or XP strategy and I will narrow it down.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Text('AI Mentor', style: GoogleFonts.poppins(fontSize: 20)),
            const Text('Powered by advanced analytics', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
          ],
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.brain, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Personal AI Coach', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.normal)),
                      const Text('Analyzing your academic journey...', style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 13)), // purple-200
                    ],
                  ),
                )
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(24),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      gradient: isUser 
                        ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)])
                        : null,
                      color: isUser ? null : AppTheme.cardColor,
                      border: isUser ? null : Border.all(color: const Color(0xFF1F2937)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['message']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                );
              },
            ),
          ),

          // Quick Suggestions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.bgColor,
              border: Border(top: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestions.map((sug) {
                      final colors = sug['colors'] as List<Color>;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            _msgCtrl.text = sug['text'] as String;
                            _handleSend();
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(sug['icon'] as IconData, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(sug['text'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      filled: true,
                      fillColor: AppTheme.bgColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: const BorderSide(color: Color(0xFF374151))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: const BorderSide(color: Color(0xFF374151))),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _handleSend,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                    ),
                    child: const Icon(LucideIcons.send, color: Colors.white, size: 24),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
