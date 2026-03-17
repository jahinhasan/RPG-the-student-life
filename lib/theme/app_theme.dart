import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgColor = Color(0xFF0B1120);
  static const Color cardColor = Color(0xFF111827);
  static const Color studentAccent = Color(0xFF3B82F6);
  static const Color teacherAccent = Color(0xFFF59E0B);
  static const Color textGray = Color(0xFF9CA3AF);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: studentAccent,
        secondary: teacherAccent,
        surface: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: studentAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: textGray,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: cardColor,
        textStyle: TextStyle(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: const TextStyle(color: textGray),
        labelStyle: const TextStyle(color: textGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: studentAccent, width: 2),
        ),
      ),
    );
  }
}
