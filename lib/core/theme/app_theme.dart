import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const Color base = Color(0xFF080C16);
    const Color panel = Color(0xFF10192A);
    const Color panelAlt = Color(0xFF14223A);
    const Color accent = Color(0xFF2AE4C9);
    const Color accentHot = Color(0xFFFF7D66);

    final TextTheme textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: base,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        surface: panel,
        surfaceContainerHighest: panelAlt,
        primary: accent,
        secondary: accentHot,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
