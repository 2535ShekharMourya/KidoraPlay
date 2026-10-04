import 'package:flutter/material.dart';

import '../../content/spelling.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'bouncy_button.dart';

/// One tile in the spelling strip.
///
/// Voiced letters are big tappable tiles that light up and bounce when
/// [highlighted]. Hyphens and spaces are shown but are not tappable.
class LetterTile extends StatelessWidget {
  const LetterTile({
    required this.tile,
    required this.accent,
    this.highlighted = false,
    this.onTap,
    this.size = AppSpacing.minTapTarget,
    super.key,
  });

  final SpellingTile tile;
  final Color accent;
  final bool highlighted;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.displayLarge!.copyWith(
          fontSize: size * 0.6,
          height: 1.1,
        );

    if (!tile.isVoiced) {
      return SizedBox(
        width: size * 0.4,
        height: size,
        child: Center(
          child: Text(tile.char.trim(), style: textStyle),
        ),
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: highlighted ? AppScale.highlighted : 1,
      duration: reduceMotion ? Duration.zero : AppDurations.highlight,
      curve: AppCurves.tap,
      child: BouncyButton(
        semanticLabel: tile.char,
        onPressed: onTap,
        sparkle: false,
        // The letter's own voice clip is the tap sound.
        sfx: null,
        minSize: size,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppDurations.highlight,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: highlighted ? accent : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: highlighted ? AppColors.outline : accent,
              width: AppStroke.thick,
            ),
            boxShadow: [
              if (highlighted)
                BoxShadow(
                  color: AppColors.glow,
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.05,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            tile.char,
            style: textStyle.copyWith(
              color: highlighted ? AppColors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
