import 'package:flutter/material.dart';

/// Centralized Material 3 theme for XPass: typography, components, and transitions.
abstract final class AppTheme {
  static const Color seedColor = Color.fromARGB(255, 117, 37, 105);

  static ThemeData light() => _build(ThemeData.light().colorScheme);

  static ThemeData dark() => _build(ThemeData.dark().colorScheme);

  static ThemeData _build(ColorScheme base) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: base.brightness,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(color: colorScheme.onSurface),
      bodyMedium: TextStyle(color: colorScheme.onSurface),
      bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
