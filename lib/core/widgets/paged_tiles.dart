import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'arrow_button.dart';
import 'tile_layout.dart';

/// A grid of [count] tiles that never shrinks them below a child-friendly
/// size: what doesn't fit goes on the next page, reached with big arrows
/// (taps only, no swiping). Fills its parent; the tiles sit inside
/// [padding] (the space between the side columns) and the arrows in the
/// side columns.
class PagedTiles extends StatefulWidget {
  const PagedTiles({
    required this.count,
    required this.builder,
    required this.arrowColor,
    this.minHeight = AppSpacing.minTapTarget,
    this.maxColumns = AppLayout.gridColumns,
    this.maxRows = AppLayout.gridRows,
    this.square = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppLayout.sideZone,
      vertical: AppSpacing.md,
    ),
    super.key,
  });

  final int count;

  /// Builds tile [index]; [slot] is its place on the page (for staggered
  /// pop-in).
  final Widget Function(BuildContext context, int index, int slot) builder;
  final Color arrowColor;
  final double minHeight;
  final int maxColumns;
  final int maxRows;
  final bool square;
  final EdgeInsets padding;

  @override
  State<PagedTiles> createState() => _PagedTilesState();
}

class _PagedTilesState extends State<PagedTiles> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = TileLayout.fit(
          Size(
            constraints.maxWidth - widget.padding.horizontal,
            constraints.maxHeight - widget.padding.vertical,
          ),
          minHeight: widget.minHeight,
          maxColumns: widget.maxColumns,
          maxRows: widget.maxRows,
          square: widget.square,
        );
        final pages = layout.pagesFor(widget.count);
        final page = _page.clamp(0, pages - 1);
        final first = page * layout.perPage;
        final last = (first + layout.perPage).clamp(0, widget.count);
        final cols = layout.columns;
        const gap = AppSpacing.tapGap;

        return Stack(
          children: [
            Padding(
              padding: widget.padding,
              child: Center(
                child: Column(
                  // A new page pops in afresh.
                  key: ValueKey(page),
                  mainAxisSize: MainAxisSize.min,
                  spacing: gap,
                  children: [
                    for (var r = first; r < last; r += cols)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: gap,
                        children: [
                          for (var i = r; i < r + cols && i < last; i++)
                            SizedBox.fromSize(
                              size: layout.tile,
                              child: widget.builder(context, i, i - first),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (page > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ArrowButton(
                    direction: ArrowDirection.previous,
                    color: widget.arrowColor,
                    onPressed: () => setState(() => _page = page - 1),
                  ),
                ),
              ),
            if (page < pages - 1)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ArrowButton(
                    direction: ArrowDirection.next,
                    color: widget.arrowColor,
                    onPressed: () => setState(() => _page = page + 1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
