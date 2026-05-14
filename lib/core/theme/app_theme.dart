import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra-Modern Tech Palette
  static const Color primary = Color(0xFF00C2FF); // Neon Cyan
  static const Color accent = Color(0xFF7000FF); // Electric Purple
  static const Color background = Color(0xFF020202); // Pure Black
  static const Color surface = Color(0xFF0F0F0F); // Deep Grey Surface
  static const Color card = Color(0xFF181818); // Elevated Card
  static const Color textPrimary = Color(0xFFF5F5F7); // Apple-style white
  static const Color textSecondary = Color(0xFF8E8E93); // iOS secondary
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: error,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.03), width: 1),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: primary.withValues(alpha: 0.1),
      thumbColor: Colors.white,
      trackHeight: 2,
      overlayColor: primary.withValues(alpha: 0.1),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
      headlineMedium: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
      titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: textSecondary),
    ),
  );
}
