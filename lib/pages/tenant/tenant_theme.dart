import 'package:flutter/material.dart';

import 'tenant_ui.dart';

ThemeData tenantTheme({required bool dark}) {
  final colors = dark ? TenantUiColors.tenantDark : TenantUiColors.tenant;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: tenantGreen,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: colors.primary,
        onPrimary: dark ? const Color(0xFF102318) : Colors.white,
        primaryContainer: colors.light,
        onPrimaryContainer: colors.dark,
        secondary: colors.dark,
        surface: colors.surface,
        onSurface: colors.ink,
        outline: colors.line,
        surfaceTint: Colors.transparent,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.surface,
    dividerColor: colors.line,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.header,
      foregroundColor: colors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: colors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputFill,
      hintStyle: TextStyle(color: colors.muted),
      labelStyle: TextStyle(color: colors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.line),
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.chipSelected,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: colors.ink, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: dark ? const Color(0xFF102318) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}
