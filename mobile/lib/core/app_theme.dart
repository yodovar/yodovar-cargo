import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Фирменные цвета: оранжевый + белый, минимализм.
abstract final class AppTheme {
  static const Color brandRed = Color(0xFFFB8C00);
  static const Color brandRedDark = Color(0xFFF57C00);
  static const Color surface = Color(0xFFFAFAFA);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandRed,
      brightness: Brightness.light,
      primary: brandRed,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.notoSansTextTheme(),
      primaryTextTheme: GoogleFonts.notoSansTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1A1A1A),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandRed,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: brandRed, width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
