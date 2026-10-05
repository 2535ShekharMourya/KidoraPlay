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

  /// Where a long word breaks onto a second line: at a hyphen or space
  /// near the middle if there is one, else in the middle.
  static int _breakAt(List<SpellingTile> tiles) {
    final middle = (tiles.length / 2).ceil();
    int? best;
    for (final (i, t) in tiles.indexed) {
      if (t.isVoiced || i == 0) continue;
      if (best == null || (i - middle).abs() < (best - middle).abs()) best = i;
    }
    return best ?? middle;
  }

  double _units(Iterable<SpellingTile> line) =>
      line.fold(0, (sum, t) => sum + (t.isVoiced ? 1 : _silentWidth));

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        double fitFor(List<SpellingTile> line) =>
            (constraints.maxWidth - gap * math.max(0, line.length - 1)) /
            math.max(1, _units(line));

        // One line if letters stay big enough; otherwise two lines.
        // Lines are (start, end) ranges of tile indexes.
        var lines = [(0, tiles.length)];
        var fit = fitFor(tiles);
        final twoLinesFit =
            constraints.maxHeight >= AppSpacing.minLetterTile * 2 + gap;
        if (fit < AppSpacing.minLetterTile && twoLinesFit && tiles.length > 3) {
          final at = _breakAt(tiles);
          // A hyphen or space at the break is not shown.
          final next = tiles[at].isVoiced ? at : at + 1;
          lines = [(0, at), (next, tiles.length)];
          fit = math.min(
            fitFor(tiles.sublist(0, at)),
            fitFor(tiles.sublist(next)),
          );
        }
        final rowHeight =
            (constraints.maxHeight - gap * (lines.length - 1)) / lines.length;
        final size = math.min(
          fit.clamp(AppSpacing.minLetterTile, AppSpacing.minTapTarget),
          rowHeight,
        );
        final rows = [
          for (final (from, to) in lines)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = from; i < to; i++) ...[
                  if (i > from) const SizedBox(width: gap),
                  _tile(i, tiles[i], size, reduceMotion),
                ],
              ],
            ),
        ];

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: rows,
            ),
          ),
        );
      },
    );
  }

  Widget _tile(int i, SpellingTile tile, double size, bool reduceMotion) =>
      IgnorePointer(
        ignoring: i >= revealed,
        child: AnimatedScale(
          scale: i < revealed ? 1 : 0,
          duration: reduceMotion ? Duration.zero : AppDurations.popIn,
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
      );
}
