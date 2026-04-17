import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const Color base = Color(0xFFF4F7F5);
    const Color panel = Color(0xFFFFFFFF);
    const Color panelAlt = Color(0xFFEFF4F1);
    const Color accent = Color(0xFF5BCB8E);
    const Color accentHot = Color(0xFF79A6FF);
    const Color textPrimary = Color(0xFF122025);
    const Color textSecondary = Color(0xFF5F7278);

    final TextTheme textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: base,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        surface: panel,
        surfaceContainerHighest: panelAlt,
        primary: accent,
        secondary: accentHot,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: base,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelAlt,
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: const Color(0xFFE3ECE7),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? textPrimary : textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }
}
