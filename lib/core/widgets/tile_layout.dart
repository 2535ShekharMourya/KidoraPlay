import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../theme/app_tokens.dart';

/// How many tiles fit on one page of a grid without any tile shrinking
/// below a child-friendly size; the rest go on further pages (arrows).
///
/// Used by every grid (Home, Numbers, item grids) so small phones get
/// fewer, bigger tiles instead of tiny or cut-off ones.
@immutable
class TileLayout {
  const TileLayout({
    required this.columns,
    required this.rows,
    required this.tile,
  });

  /// Fits tiles into [space] (the content area between the side columns).
  /// Tiles are at least [minWidth] × [minHeight] with [gap] between them;
  /// at most [maxColumns] × [maxRows] per page. With [square], tiles are
  /// as wide as they are tall.
  factory TileLayout.fit(
    Size space, {
    double minWidth = AppSpacing.minTapTarget,
    double minHeight = AppSpacing.minTapTarget,
    int maxColumns = AppLayout.gridColumns,
    int maxRows = AppLayout.gridRows,
    double gap = AppSpacing.tapGap,
    bool square = false,
  }) {
    int count(double room, double min, int max) =>
        ((room + gap) / (min + gap)).floor().clamp(1, max);

    final columns = count(space.width, minWidth, maxColumns);
    final rows = count(space.height, minHeight, maxRows);
    var width = (space.width - gap * (columns - 1)) / columns;
    var height = (space.height - gap * (rows - 1)) / rows;
    if (square) width = height = math.min(width, height);
    return TileLayout(
      columns: columns,
      rows: rows,
      tile: Size(math.max(width, minWidth), math.max(height, minHeight)),
    );
  }

  final int columns;
  final int rows;
  final Size tile;

  int get perPage => columns * rows;

  int pagesFor(int items) => math.max(1, (items / perPage).ceil());
}
