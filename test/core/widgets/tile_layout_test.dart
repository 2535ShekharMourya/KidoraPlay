import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/tile_layout.dart';

void main() {
  test('20:9 phone: two rows of five', () {
    // 800×360 minus the side columns and padding.
    final l = TileLayout.fit(const Size(544, 296), square: true);
    expect((l.columns, l.rows), (5, 2));
    expect(l.perPage, 10);
    expect(l.tile.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
  });

  test('small 16:9 phone: fewer, bigger tiles, the rest on pages', () {
    final l = TileLayout.fit(const Size(384, 296), square: true);
    expect(l.columns, 3);
    expect(l.rows, 2);
    expect(l.tile.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    expect(l.tile.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    expect(l.pagesFor(10), 2);
  });

  test('tiles never go below the minimum, even in a tiny space', () {
    final l = TileLayout.fit(const Size(50, 50));
    expect((l.columns, l.rows), (1, 1));
    expect(l.tile, const Size(96, 96));
  });

  test('Home: taller section tiles on short screens', () {
    final l = TileLayout.fit(
      const Size(384, 296),
      minHeight: AppLayout.sectionTileMinHeight,
    );
    expect(l.tile.height, greaterThanOrEqualTo(120));
    expect(l.rows, 2);
  });
}
