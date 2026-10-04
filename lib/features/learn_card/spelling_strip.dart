import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/spelling.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/letter_tile.dart';

/// A row of letter tiles that appear one by one and light up as each
/// letter is spoken. Tiles keep their place while hidden so nothing jumps.
class SpellingStrip extends StatelessWidget {
  const SpellingStrip({
    required this.tiles,
    required this.revealed,
    required this.highlighted,
    required this.accent,
    required this.onTapLetter,
    super.key,
  });

  final List<SpellingTile> tiles;
  final int revealed;
  final int? highlighted;
  final Color accent;
  final void Function(int index) onTapLetter;

  /// Silent tiles (hyphen, space) are narrower than letters.
  static const _silentWidth = 0.4;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final units = tiles.fold<double>(
          0,
          (sum, t) => sum + (t.isVoiced ? 1 : _silentWidth),
        );
        final fit =
            (constraints.maxWidth - gap * math.max(0, tiles.length - 1)) /
                math.max(1, units);
        final size = math.min(
          fit.clamp(AppSpacing.minLetterTile, AppSpacing.minTapTarget),
          constraints.maxHeight,
        );

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, tile) in tiles.indexed) ...[
                  if (i > 0) const SizedBox(width: gap),
                  IgnorePointer(
                    ignoring: i >= revealed,
                    child: AnimatedScale(
                      scale: i < revealed ? 1 : 0,
                      duration:
                          reduceMotion ? Duration.zero : AppDurations.popIn,
                      curve: AppCurves.popIn,
                      child: LetterTile(
                        tile: tile,
                        accent: accent,
                        size: size,
                        highlighted: highlighted == i,
                        onTap: () => onTapLetter(i),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
