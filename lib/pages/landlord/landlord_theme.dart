import 'package:flutter/material.dart';

/// Colors used by the landlord workspace.
class LandlordPalette {
  const LandlordPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color line;
  final Color primary;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;

  static const light = LandlordPalette(
    canvas: Color(0xFFF4F9FD),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5FAFE),
    ink: Color(0xFF183247),
    muted: Color(0xFF6E8495),
    line: Color(0xFFE1ECF4),
    primary: Color(0xFF1682C4),
    primarySoft: Color(0xFFE4F3FC),
    accent: Color(0xFF0C6BA8),
    accentSoft: Color(0xFFEAF6FD),
  );

  static const dark = LandlordPalette(
    canvas: Color(0xFF101B25),
    surface: Color(0xFF1A2935),
    surfaceAlt: Color(0xFF223746),
    ink: Color(0xFFF1F7FC),
    muted: Color(0xFFB5C7D5),
    line: Color(0xFF344B5C),
    primary: Color(0xFF71C4F3),
    primarySoft: Color(0xFF23485F),
    accent: Color(0xFF71C4F3),
    accentSoft: Color(0xFF23485F),
  );

  static LandlordPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData landlordTheme({required bool dark}) {
  final palette = dark ? LandlordPalette.dark : LandlordPalette.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1682C4),
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: palette.primary,
        onPrimary: dark ? const Color(0xFF092537) : Colors.white,
        primaryContainer: palette.primarySoft,
        onPrimaryContainer: palette.accent,
        secondary: palette.accent,
        surface: palette.surface,
        onSurface: palette.ink,
        outline: palette.line,
        surfaceTint: Colors.transparent,
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.canvas,
    cardColor: palette.surface,
    dividerColor: palette.line,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: palette.ink,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceAlt,
      hintStyle: TextStyle(color: palette.muted, fontSize: 13),
      labelStyle: TextStyle(color: palette.muted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceAlt,
      selectedColor: palette.primarySoft,
      side: BorderSide(color: palette.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: TextStyle(
        color: palette.ink,
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.primarySoft,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 46),
        foregroundColor: palette.accent,
        side: BorderSide(color: palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: DividerThemeData(color: palette.line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF253D4E) : const Color(0xFF163B55),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
