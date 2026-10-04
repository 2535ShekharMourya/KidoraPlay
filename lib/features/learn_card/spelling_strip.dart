import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/spelling.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/beckon.dart';
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
    this.beckonIndex,
    this.strongBeckon = false,
    this.tileKeys,
    super.key,
  });

  final List<SpellingTile> tiles;
  final int revealed;
  final int? highlighted;
  final Color accent;
  final void Function(int index) onTapLetter;

  /// Tile calling for a tap ("we do"), glowing; bouncing when [strongBeckon].
  final int? beckonIndex;
  final bool strongBeckon;

  /// Optional keys so Kido can find each tile on screen.
  final List<GlobalKey>? tileKeys;

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
                      child: Beckon(
                        key: tileKeys?[i],
                        active: beckonIndex == i,
                        strong: strongBeckon,
                        radius: AppRadii.md,
                        child: LetterTile(
                          tile: tile,
                          accent: accent,
                          size: size,
                          highlighted: highlighted == i,
                          onTap: () => onTapLetter(i),
                        ),
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
