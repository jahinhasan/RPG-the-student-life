import 'dart:math';

class LevelCalculator {
  /// Calculates the level based on total XP.
  /// Using a simple quadratic formula: Level = floor(sqrt(XP / 100)) + 1
  static int getLevel(int xp) {
    if (xp <= 0) return 1;
    return (sqrt(xp / 100)).floor() + 1;
  }

  /// Calculates total XP required for a specific level.
  static int getXPForLevel(int level) {
    if (level <= 1) return 0;
    return (pow(level - 1, 2) * 100).toInt();
  }

  /// Calculates progress (0.0 to 1.0) towards the next level.
  static double getLevelProgress(int xp) {
    int currentLevel = getLevel(xp);
    int xpAtCurrentLevel = getXPForLevel(currentLevel);
    int xpForNextLevel = getXPForLevel(currentLevel + 1);
    
    int xpInCurrentLevel = xp - xpAtCurrentLevel;
    int totalXpNeededForNextLevel = xpForNextLevel - xpAtCurrentLevel;
    
    return (xpInCurrentLevel / totalXpNeededForNextLevel).clamp(0.0, 1.0);
  }
}
