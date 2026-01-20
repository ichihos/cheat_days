import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.mPlusRounded1c().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8C00), // Vibrant Orange
      brightness: Brightness.light,
      primary: const Color(0xFFFF8C00),
      secondary: const Color(0xFF4ECDC4), // Turquoise
      surface: const Color(0xFFFFF9F5), // Warm off-white
      surfaceContainerHighest: const Color(0xFFFFE0B2),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF9F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFF9F5),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
  );
}
