import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Bundled font family (assets/fonts, OFL). Supports Latin + Devanagari.
const kFontFamily = 'Baloo2';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.numbersAccent,
      surface: AppColors.cream,
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: kFontFamily,
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: NoSplash.splashFactory,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
