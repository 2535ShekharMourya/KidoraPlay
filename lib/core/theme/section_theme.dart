import 'package:flutter/material.dart';

import '../../content/models/section.dart';
import 'app_colors.dart';

/// Per-section colour theme.
@immutable
class SectionTheme {
  const SectionTheme({required this.background, required this.accent});

  final Color background;
  final Color accent;

  static SectionTheme of(SectionId id) => switch (id) {
    SectionId.numbers => const SectionTheme(
      background: AppColors.numbersBg,
      accent: AppColors.numbersAccent,
    ),
    SectionId.abc => const SectionTheme(
      background: AppColors.abcBg,
      accent: AppColors.abcAccent,
    ),
    SectionId.animals => const SectionTheme(
      background: AppColors.animalsBg,
      accent: AppColors.animalsAccent,
    ),
    SectionId.birds => const SectionTheme(
      background: AppColors.birdsBg,
      accent: AppColors.birdsAccent,
    ),
    SectionId.fruits => const SectionTheme(
      background: AppColors.fruitsBg,
      accent: AppColors.fruitsAccent,
    ),
    SectionId.vegetables => const SectionTheme(
      background: AppColors.vegetablesBg,
      accent: AppColors.vegetablesAccent,
    ),
    SectionId.colours => const SectionTheme(
      background: AppColors.coloursBg,
      accent: AppColors.coloursAccent,
    ),
    SectionId.shapes => const SectionTheme(
      background: AppColors.shapesBg,
      accent: AppColors.shapesAccent,
    ),
  };
}
