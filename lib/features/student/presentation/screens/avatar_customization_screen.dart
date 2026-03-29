import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class AvatarCustomizationScreen extends ConsumerStatefulWidget {
  const AvatarCustomizationScreen({super.key});

  @override
  ConsumerState<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends ConsumerState<AvatarCustomizationScreen> {
  String activeTab = 'outfit';

  final outfits = [
    {'id': '1', 'emoji': '👨‍🎓', 'name': 'Scholar Robe', 'level': 1, 'unlocked': true},
    {'id': '2', 'emoji': '🧑‍💼', 'name': 'Business Attire', 'level': 5, 'unlocked': false},
    {'id': '3', 'emoji': '🧑‍🔬', 'name': 'Lab Coat', 'level': 10, 'unlocked': false},
    {'id': '4', 'emoji': '🧙', 'name': 'Master Wizard', 'level': 15, 'unlocked': false},
  ];

  final accessories = [
    {'id': '1', 'emoji': '🎓', 'name': 'Graduation Cap', 'level': 1, 'unlocked': true},
    {'id': '2', 'emoji': '👓', 'name': 'Wisdom Glasses', 'level': 3, 'unlocked': false},
    {'id': '3', 'emoji': '⌚', 'name': 'Time Master Watch', 'level': 7, 'unlocked': false},
  ];

  final badges = [
    {'id': '1', 'emoji': '🏆', 'name': 'First Victory', 'level': 1, 'unlocked': true},
    {'id': '2', 'emoji': '⭐', 'name': 'Perfect Attendance', 'level': 5, 'unlocked': false},
    {'id': '3', 'emoji': '💎', 'name': 'Diamond Student', 'level': 10, 'unlocked': false},
  ];

  List<Map<String, dynamic>> _getItems() {
    switch (activeTab) {
      case 'outfit': return outfits;
      case 'accessories': return accessories;
      case 'badges': return badges;
      default: return [];
    }
  }

  Future<void> _equipItem(Map<String, dynamic> item) async {
    await ref.read(xpServiceProvider).saveAvatarSelection(
          category: activeTab,
          emoji: item['emoji'] as String,
          name: item['name'] as String,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} equipped successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    final userStatsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Avatar Customization', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: userStatsAsync.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentLevel = stats['level'] as int? ?? 1;
          final avatarEmoji = (stats['avatar'] ?? '👨‍🎓') as String;
          final selectedName = switch (activeTab) {
            'outfit' => stats['selectedOutfit'],
            'accessories' => stats['selectedAccessory'],
            _ => stats['selectedBadge'],
          };

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF111827)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.studentAccent,
                      child: Text(avatarEmoji, style: const TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (stats['name'] ?? 'Student') as String,
                      style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text('Level $currentLevel', style: const TextStyle(color: AppTheme.textGray)),
                  ],
                ),
              ),
              _buildTabs(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isUnlocked = currentLevel >= (item['level'] as int);
                    final isEquipped = selectedName == item['name'];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        border: Border.all(
                          color: isEquipped
                              ? AppTheme.studentAccent
                              : (isUnlocked ? const Color(0xFF374151) : const Color(0xFF1F2937)),
                          width: isEquipped ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item['emoji'] as String, style: TextStyle(fontSize: 48, color: isUnlocked ? Colors.white : Colors.white24)),
                              const SizedBox(height: 12),
                              Text(
                                item['name'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 14, color: isUnlocked ? Colors.white : Colors.white54),
                              ),
                              const SizedBox(height: 4),
                              Text('Unlock: Lv.${item['level']}', style: TextStyle(fontSize: 12, color: isUnlocked ? AppTheme.textGray : Colors.white38)),
                              if (isUnlocked)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isEquipped ? null : () => _equipItem(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isEquipped ? const Color(0xFF10B981) : AppTheme.studentAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      child: Text(isEquipped ? 'Equipped' : 'Equip', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                )
                            ],
                          ),
                          if (!isUnlocked)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.lock, color: AppTheme.textGray, size: 32),
                                    const SizedBox(height: 8),
                                    Text('Level ${item['level']}', style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['outfit', 'accessories', 'badges'];
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
}
