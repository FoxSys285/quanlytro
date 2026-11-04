import 'package:flutter/material.dart';

/// Colors used only by the landlord workspace.
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
    canvas: Color(0xFFFAFBFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F4FD),
    ink: Color(0xFF20243A),
    muted: Color(0xFF687086),
    line: Color(0xFFE5E9F2),
    primary: Color(0xFF405FC6),
    primarySoft: Color(0xFFE8EDFF),
    accent: Color(0xFF3659B8),
    accentSoft: Color(0xFFE8EDFF),
  );

  static const dark = LandlordPalette(
    canvas: Color(0xFF101521),
    surface: Color(0xFF1B2333),
    surfaceAlt: Color(0xFF263149),
    ink: Color(0xFFF5F7FF),
    muted: Color(0xFFBBC5D9),
    line: Color(0xFF36425A),
    primary: Color(0xFFA9BCFF),
    primarySoft: Color(0xFF303F69),
    accent: Color(0xFFA9BCFF),
    accentSoft: Color(0xFF303F69),
  );

  static LandlordPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData landlordTheme({required bool dark}) {
  final palette = dark ? LandlordPalette.dark : LandlordPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF405FC6),
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(
      primary: palette.primary,
      onPrimary: dark ? const Color(0xFF172344) : Colors.white,
      surface: palette.surface,
      onSurface: palette.ink,
      outline: palette.line,
    ),
    scaffoldBackgroundColor: palette.canvas,
    cardColor: palette.surface,
    dividerColor: palette.line,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.line),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
