import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDark       = Color(0xFF0A0A0F);
  static const Color bgCard       = Color(0xFF14141F);
  static const Color bgElevated   = Color(0xFF1E1E2E);
  static const Color redVF        = Color(0xFFE60028);
  static const Color redGlow      = Color(0xFFFF2244);
  static const Color redDark      = Color(0xFFB80020);
  static const Color gold         = Color(0xFFFFD700);
  static const Color goldDim      = Color(0xFFB8860B);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color textPrimary  = Color(0xFFF0F0F5);
  static const Color textSecondary= Color(0xFF8A8A9A);
  static const Color textMuted    = Color(0xFF5A5A6A);
  static const Color success      = Color(0xFF00E676);
  static const Color error        = Color(0xFFFF1744);
  static const Color warning      = Color(0xFFFF9100);
  static const Color info         = Color(0xFF00B0FF);
  static const Color purple       = Color(0xFF7C4DFF);
  static const Color teal         = Color(0xFF00E5FF);

  static BoxDecoration glowCard({Color? glowColor}) => BoxDecoration(
    color: bgCard,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: (glowColor ?? redVF).withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: (glowColor ?? redVF).withOpacity(0.15),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration gradientCard() => BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1E1E2E), Color(0xFF14141F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: white.withOpacity(0.06),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: redVF,
      secondary: gold,
      surface: bgCard,
      background: bgDark,
      error: error,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.w900),
      titleLarge: GoogleFonts.cairo(color: textPrimary, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.cairo(color: textPrimary),
      bodyMedium: GoogleFonts.cairo(color: textSecondary),
      labelLarge: GoogleFonts.cairo(color: textSecondary, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: redVF,
        foregroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 8,
        shadowColor: redVF.withOpacity(0.4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: redVF, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.cairo(color: textMuted),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
