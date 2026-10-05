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
    this.badge,
    super.key,
  });

  final String image;
  final String fallbackText;
  final Color accent;

  /// Text shown on the picture's corner (a Hindi letter).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final picture = _picture(context);
    final badge = this.badge;
    if (badge == null) return picture;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.36;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: picture),
            Positioned(
              left: -size * 0.12,
              top: -size * 0.12,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outline,
                    width: AppStroke.thin,
                  ),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.12),
                    child: Text(
                      badge,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white, height: 1.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _picture(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: accent, width: AppStroke.thick),
      ),
      // Inset by the border width so photos never cover the frame.
      child: Padding(
        padding: const EdgeInsets.all(AppStroke.thick),
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
      ),
    );
  }
}
