import 'package:flutter/material.dart';

class GameConstants {
  static const int baseXPPerLevel = 1000;
  static const double xpMultiplier = 1.2;

  // XP Rewards
  static const int xpMissionSmall = 100;
  static const int xpMissionMedium = 250;
  static const int xpMissionLarge = 500;
  static const int xpArenaWin = 200;
  static const int xpMiniGameWin = 50;

  static const List<Color> studentGradient = [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
  static const List<Color> teacherGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
}
