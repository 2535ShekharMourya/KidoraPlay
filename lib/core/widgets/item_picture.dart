import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A learning item's picture in a rounded card. If the image is missing it
/// falls back to the word, so the child still sees something.
class ItemPicture extends StatelessWidget {
  const ItemPicture({
    required this.image,
    required this.fallbackText,
    required this.accent,
    super.key,
  });

  final String image;
  final String fallbackText;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: accent, width: AppStroke.thick),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card - AppStroke.thick),
        child: Image.asset(
          image,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  fallbackText,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
