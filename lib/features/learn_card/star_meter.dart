import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// The card's goal at a glance: one star slot per discovery tap. Earned
/// stars pop in gold; the rest wait as soft outlines.
class StarMeter extends StatelessWidget {
  const StarMeter({required this.stars, required this.goal, super.key});

  final int stars;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '$stars / $goal',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < goal; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : AppDurations.popIn,
                switchInCurve: AppCurves.popIn,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey(i < stars),
                  size: AppLayout.starMeter,
                  color: i < stars ? AppColors.celebrate : AppColors.outline,
                  shadows: i < stars
                      ? const [Shadow(color: AppColors.outline, blurRadius: 2)]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
