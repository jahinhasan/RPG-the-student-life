import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../routes.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';
import '../utils/level_calculator.dart';

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final worldStudentsAsync = ref.watch(worldMapStudentsProvider);

    return userStatsAsync.when(
      data: (stats) {
        final currentUid = (stats?['uid'] ?? '') as String;
        final currentLevel = stats?['level'] as int? ?? 1;
        final currentName = (stats?['name'] ?? 'You') as String;
        final currentAvatar = (stats?['avatar'] ?? '👨‍🎓') as String;

        final worldZones = [
          {'id': 'classroom', 'name': 'Classroom', 'requiredLevel': 1},
          {'id': 'laboratory', 'name': 'Laboratory', 'requiredLevel': 5},
          {'id': 'library', 'name': 'Library', 'requiredLevel': 10},
          {'id': 'arena', 'name': 'Arena', 'requiredLevel': 15},
          {'id': 'graduation', 'name': 'Graduation Tower', 'requiredLevel': 20},
        ];

        final nodePositions = [
          {'x': 50.0, 'y': 88.0},
          {'x': 50.0, 'y': 75.0},
          {'x': 70.0, 'y': 62.0},
          {'x': 45.0, 'y': 50.0},
          {'x': 50.0, 'y': 30.0},
        ];

        final decorations = [
          {'emoji': '🌳', 'x': 15.0, 'y': 15.0, 'size': 44.0},
          {'emoji': '🌳', 'x': 75.0, 'y': 20.0, 'size': 40.0},
          {'emoji': '🪨', 'x': 10.0, 'y': 40.0, 'size': 30.0},
          {'emoji': '🪨', 'x': 80.0, 'y': 45.0, 'size': 30.0},
          {'emoji': '🌺', 'x': 85.0, 'y': 65.0, 'size': 24.0},
          {'emoji': '🌸', 'x': 20.0, 'y': 70.0, 'size': 24.0},
          {'emoji': '🦋', 'x': 12.0, 'y': 55.0, 'size': 20.0},
          {'emoji': '🌿', 'x': 78.0, 'y': 80.0, 'size': 24.0},
          {'emoji': '🍄', 'x': 25.0, 'y': 85.0, 'size': 20.0},
          {'emoji': '🌼', 'x': 70.0, 'y': 35.0, 'size': 20.0},
        ];

        return worldStudentsAsync.when(
          data: (students) {
            final normalizedStudents = students
                .map((student) => {
                      'uid': (student['uid'] ?? '') as String,
                      'name': (student['name'] ?? 'Student') as String,
                      'avatar': (student['avatar'] ?? '👨‍🎓') as String,
                      'xp': (student['xp'] is num) ? (student['xp'] as num).toInt() : 0,
                      'level': (student['level'] is num) ? (student['level'] as num).toInt() : LevelCalculator.getLevel((student['xp'] is num) ? (student['xp'] as num).toInt() : 0),
                    })
                .toList();

            final currentAlreadyPresent = normalizedStudents.any((student) => student['uid'] == currentUid);
            if (!currentAlreadyPresent && currentUid.isNotEmpty) {
              final currentXp = (stats?['xp'] is num) ? (stats?['xp'] as num).toInt() : 0;
              normalizedStudents.add({
                'uid': currentUid,
                'name': currentName,
                'avatar': currentAvatar,
                'xp': currentXp,
                'level': currentLevel,
              });
            }

            normalizedStudents.sort((a, b) => ((b['xp'] as int)).compareTo(a['xp'] as int));
            final maxMapLevel = (worldZones.last['requiredLevel'] as int?) ?? 20;

            final livePathMarkers = <Widget>[];
            for (var i = 0; i < normalizedStudents.length; i++) {
              final student = normalizedStudents[i];
              final xp = student['xp'] as int;
              final level = (student['level'] as int).clamp(1, 999);
              final inLevelProgress = LevelCalculator.getLevelProgress(xp);
              final baseProgress = ((level - 1) / (maxMapLevel - 1)).clamp(0.0, 1.0);
              final fineProgress = (inLevelProgress / (maxMapLevel - 1)).clamp(0.0, 1.0);
              final progress = (baseProgress + fineProgress).clamp(0.0, 1.0);
              final pathPoint = _positionAlongPath(progress, nodePositions);
              final isCurrentUser = student['uid'] == currentUid;
              final lateralOffset = ((i % 3) - 1) * 18.0;

              livePathMarkers.add(
                Positioned(
                  left: (MediaQuery.of(context).size.width * (pathPoint['x']! / 100)) - 44 + lateralOffset,
                  top: (820 * (pathPoint['y']! / 100)) - 46,
                  child: _buildPathStudentMarker(
                    name: isCurrentUser ? 'You' : student['name'] as String,
                    avatar: student['avatar'] as String,
                    xp: xp,
                    isCurrentUser: isCurrentUser,
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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('World Map', style: GoogleFonts.poppins(fontSize: 20)),
                    const Text('Live student positions', style: TextStyle(color: AppTheme.studentAccent, fontSize: 12)),
                  ],
                ),
                backgroundColor: const Color(0xFF1F2937),
                elevation: 0,
              ),
              bottomNavigationBar: _buildBottomNav(context),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF081226), Color(0xFF112947), Color(0xFF1A3D5A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0B162A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A4C73)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D3557),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF5FA8FF), width: 2),
                            ),
                            child: Center(child: Text(currentAvatar, style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Level $currentLevel explorer', style: GoogleFonts.poppins(color: const Color(0xFF9BC4FF), fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.gamepad2, color: Color(0xFF9BC4FF), size: 18),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2A4C73), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, 10)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SingleChildScrollView(
                              child: SizedBox(
                                height: 820,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF65D77F), Color(0xFF3FAE5D), Color(0xFF2D8A4A)],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: -60,
                                      top: 40,
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0x22FFFFFF),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -40,
                                      top: 180,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0x1FFFFFFF),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        height: 120,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...decorations.map((decoration) => Positioned(
                                          left: MediaQuery.of(context).size.width * ((decoration['x'] as double) / 100),
                                          top: 820 * ((decoration['y'] as double) / 100),
                                          child: Text(
                                            decoration['emoji'] as String,
                                            style: TextStyle(fontSize: decoration['size'] as double),
                                          ),
                                        )),
                                    CustomPaint(
                                      size: Size(MediaQuery.of(context).size.width, 820),
                                      painter: _WorldPathPainter(nodePositions: nodePositions),
                                    ),
                                    ...List.generate(worldZones.length, (index) {
                                      final zone = worldZones[index];
                                      final position = nodePositions[index];
                                      final requiredLevel = zone['requiredLevel'] as int;
                                      final isUnlocked = currentLevel >= requiredLevel;
                                      return _buildNode(
                                        context,
                                        zone: zone,
                                        position: position,
                                        isUnlocked: isUnlocked,
                                      );
                                    }),
                                    ...livePathMarkers,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildNode(
    BuildContext context, {
    required Map<String, dynamic> zone,
    required Map<String, double> position,
    required bool isUnlocked,
  }) {
    final width = MediaQuery.of(context).size.width;

    return Positioned(
      left: width * (position['x']! / 100) - 40,
      top: 820 * (position['y']! / 100) - 40,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isUnlocked
            ? () => Navigator.pushNamed(
                  context,
                  AppRoutes.worldScene,
                  arguments: {
                    'id': zone['id'],
                    'name': zone['name'],
                    'level': zone['requiredLevel'],
                  },
                )
            : null,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isUnlocked 
                      ? const [Color(0xFF8B7355), Color(0xFF6B5845)]
                      : const [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 8), blurRadius: 15),
                ],
              ),
              child: Center(
                child: isUnlocked 
                    ? Text('${zone['requiredLevel']}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
                    : const Text('🔒', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Text(zone['name'] as String, style: GoogleFonts.poppins(color: AppTheme.cardColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _positionAlongPath(double progress, List<Map<String, double>> nodePositions) {
    if (nodePositions.length < 2) {
      return {'x': 50.0, 'y': 88.0};
    }

    final clamped = progress.clamp(0.0, 1.0);
    final totalSegments = nodePositions.length - 1;
    final scaled = clamped * totalSegments;
    final startIndex = scaled.floor().clamp(0, totalSegments - 1);
    final localT = scaled - startIndex;

    final start = nodePositions[startIndex];
    final end = nodePositions[startIndex + 1];

    return {
      'x': start['x']! + (end['x']! - start['x']!) * localT,
      'y': start['y']! + (end['y']! - start['y']!) * localT,
    };
  }

  Widget _buildPathStudentMarker({
    required String name,
    required String avatar,
    required int xp,
    required bool isCurrentUser,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isCurrentUser ? const Color(0xFFEAB308) : const Color(0xEE0F172A),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isCurrentUser ? const Color(0xFF92400E) : const Color(0xFF334155)),
          ),
          child: Text(
            '$name • $xp XP',
            style: GoogleFonts.poppins(
              color: isCurrentUser ? const Color(0xFF111827) : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCurrentUser ? const Color(0xFFF59E0B) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0F172A), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(avatar, style: const TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppTheme.cardColor,
      selectedItemColor: AppTheme.studentAccent,
      unselectedItemColor: AppTheme.textGray,
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.studentHome, (route) => false);
        }
        if (index == 2) Navigator.pushNamed(context, AppRoutes.leaderboard);
        if (index == 3) Navigator.pushNamed(context, AppRoutes.profile);
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

class _WorldPathPainter extends CustomPainter {
  _WorldPathPainter({required this.nodePositions});

  final List<Map<String, double>> nodePositions;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = const Color(0x993B240D)
      ..strokeWidth = 72
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = const Color(0xFFA06A3C)
      ..strokeWidth = 64
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFE8C08D)
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerLinePaint = Paint()
      ..color = const Color(0xCCFFF7ED)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < nodePositions.length - 1; index++) {
      final start = Offset(
        size.width * (nodePositions[index]['x']! / 100),
        size.height * (nodePositions[index]['y']! / 100),
      );
      final end = Offset(
        size.width * (nodePositions[index + 1]['x']! / 100),
        size.height * (nodePositions[index + 1]['y']! / 100),
      );

      canvas.drawLine(start.translate(0, 4), end.translate(0, 4), shadowPaint);
      canvas.drawLine(start, end, borderPaint);
      canvas.drawLine(start, end, fillPaint);

      final segmentVector = end - start;
      final segmentLength = segmentVector.distance;
      if (segmentLength > 0) {
        final unit = Offset(segmentVector.dx / segmentLength, segmentVector.dy / segmentLength);
        const dashLength = 10.0;
        const gap = 8.0;
        var distance = 0.0;
        while (distance < segmentLength) {
          final dashStart = start + unit * distance;
          final dashEndDistance = (distance + dashLength).clamp(0.0, segmentLength);
          final dashEnd = start + unit * dashEndDistance;
          canvas.drawLine(dashStart, dashEnd, centerLinePaint);
          distance += dashLength + gap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
