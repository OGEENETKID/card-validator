import 'package:flutter/material.dart';

/// Design tokens. Neutral surfaces with colour reserved for status.
abstract final class AppColors {
  static const ink = Color(0xFF121820);
  static const paper = Color(0xFFF2F4F6);
  static const surface = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFDDE2E8);
  static const muted = Color(0xFF67717E);
  static const action = Color(0xFF0B5551);
  static const accepted = Color(0xFF2C6B4F);
  static const rejected = Color(0xFF9E3328);
}

abstract final class AppTheme {
  /// Resolves to the platform monospace face.
  static const String monoFamily = 'monospace';

  static ThemeData build() {
    const scheme = ColorScheme.light(
      primary: AppColors.action,
      onPrimary: Colors.white,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.rejected,
      onError: Colors.white,
    );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      dividerColor: AppColors.hairline,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
          .copyWith(
            titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
            bodyMedium: const TextStyle(fontSize: 15, height: 1.45),
            bodySmall: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: _border(AppColors.hairline),
        enabledBorder: _border(AppColors.hairline),
        focusedBorder: _border(AppColors.action, width: 1.6),
        errorBorder: _border(AppColors.rejected),
        focusedErrorBorder: _border(AppColors.rejected, width: 1.6),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
        floatingLabelStyle: const TextStyle(color: AppColors.action, fontSize: 14),
        errorStyle: const TextStyle(color: AppColors.rejected, fontSize: 13, height: 1.35),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.hairline),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: color, width: width),
      );

  static const TextStyle pan = TextStyle(
    fontFamily: monoFamily,
    fontSize: 19,
    letterSpacing: 1.6,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
}
