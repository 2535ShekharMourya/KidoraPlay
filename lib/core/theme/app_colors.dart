import 'package:flutter/material.dart';

/// Colour tokens. Widgets must use these, never raw `Color(...)` values.
///
/// Pastels are for backgrounds; saturated colours are reserved for
/// tappable items.
abstract final class AppColors {
  // Neutrals
  static const ink = Color(0xFF2E2A47);
  static const outline = Color(0xFF3B3561);
  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFFF8EC);

  // Kido
  static const kidoGrey = Color(0xFF9FB4D1);
  static const kidoPink = Color(0xFFFFB3C7);

  // Feedback
  static const success = Color(0xFF4CC38A);
  static const celebrate = Color(0xFFFFC93C);

  // Section themes: pastel background + saturated accent
  static const numbersBg = Color(0xFFDDF1FF);
  static const numbersAccent = Color(0xFF2E9BFF);
  static const abcBg = Color(0xFFFFF4C7);
  static const abcAccent = Color(0xFFFFB800);
  static const animalsBg = Color(0xFFDDF5DC);
  static const animalsAccent = Color(0xFF3DB24B);
  static const birdsBg = Color(0xFFFFE6D3);
  static const birdsAccent = Color(0xFFFF7A2F);
}
