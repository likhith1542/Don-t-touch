import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color bgPrimary = Color(0xFF080B14);
  static const Color bgSecondary = Color(0xFF0E1220);
  static const Color bgCard = Color(0xFF141828);
  static const Color bgCardAlt = Color(0xFF1A1F30);

  static const Color accentRed = Color(0xFFFF2D55);
  static const Color accentRedDim = Color(0x33FF2D55);
  static const Color accentGreen = Color(0xFF00FF9D);
  static const Color accentGreenDim = Color(0x2200FF9D);
  static const Color accentBlue = Color(0xFF4F8EFF);
  static const Color accentBlueDim = Color(0x334F8EFF);
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentOrangeDim = Color(0x33FF8C42);

  static const Color textPrimary = Color(0xFFEEF0F8);
  static const Color textSecondary = Color(0xFF8892AA);
  static const Color textTertiary = Color(0xFF4A5168);

  static const Color borderColor = Color(0xFF1E2538);
  static const Color borderColorBright = Color(0xFF2A3350);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        background: bgPrimary,
        surface: bgSecondary,
        primary: accentRed,
        secondary: accentGreen,
        error: accentRed,
        onBackground: textPrimary,
        onSurface: textPrimary,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1.5),
          displayMedium: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -1.2),
          headlineLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.8),
          headlineMedium: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineSmall: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textTertiary),
          labelLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ).apply(
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
