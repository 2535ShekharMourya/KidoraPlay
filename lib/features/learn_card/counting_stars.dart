import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Number cards up to 20: the numeral and that many stars. While Kido
/// counts, each star lights up and grows as its number is said ("1… only
/// one!"), so the child sees what the number means.
class CountingStars extends StatelessWidget {
  const CountingStars({
    required this.number,
    required this.counted,
    required this.accent,
    super.key,
  });

  final int number;

  /// Stars counted so far (0 = not counting: all stars shown plainly).
  final int counted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final counting = counted > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: accent, width: AppStroke.thick),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // One row up to five, then rows of five (ten frames).
          final perRow = math.min(number, 5);
          final rows = (number / perRow).ceil();
          final side = constraints.biggest.shortestSide;
          final star = math.min(
            (constraints.maxWidth * 0.86) / perRow,
            (constraints.maxHeight * 0.55) / rows,
          );
          return Padding(
            padding: EdgeInsets.all(side * 0.04),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    child: Text(
                      '$number',
                      style: Theme.of(context).textTheme.displayLarge
                          ?.copyWith(color: accent),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    // Rows of five, like a ten-frame: easy to count.
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var r = 0; r * perRow < number; r++)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var i = r * perRow + 1;
                                i <= math.min(number, (r + 1) * perRow);
                                i++
                              )
                                _star(i, star, counting, reduceMotion),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _star(int i, double size, bool counting, bool reduceMotion) =>
      SizedBox.square(
        dimension: size,
        child: AnimatedScale(
          scale: counting && i == counted ? 1.35 : 1,
          duration: reduceMotion ? Duration.zero : AppDurations.highlight,
          curve: AppCurves.tap,
          child: Icon(
            Icons.star_rounded,
            size: size,
            // Counting: counted stars gold, the rest waiting in soft grey.
            color: !counting || i <= counted
                ? AppColors.celebrate
                : AppColors.traceRoadEdge,
            shadows: counting && i == counted
                ? const [Shadow(color: AppColors.glow, blurRadius: 12)]
                : null,
          ),
        ),
      );
}
