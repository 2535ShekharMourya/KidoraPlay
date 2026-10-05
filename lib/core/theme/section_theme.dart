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
    SectionId.hindi => const SectionTheme(
      background: AppColors.hindiBg,
      accent: AppColors.hindiAccent,
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
    SectionId.vehicles => const SectionTheme(
      background: AppColors.vehiclesBg,
      accent: AppColors.vehiclesAccent,
    ),
    SectionId.body => const SectionTheme(
      background: AppColors.bodyBg,
      accent: AppColors.bodyAccent,
    ),
    SectionId.family => const SectionTheme(
      background: AppColors.familyBg,
      accent: AppColors.familyAccent,
    ),
    SectionId.days => const SectionTheme(
      background: AppColors.daysBg,
      accent: AppColors.daysAccent,
    ),
    SectionId.months => const SectionTheme(
      background: AppColors.monthsBg,
      accent: AppColors.monthsAccent,
    ),
    SectionId.opposites => const SectionTheme(
      background: AppColors.oppositesBg,
      accent: AppColors.oppositesAccent,
    ),
  };
}
