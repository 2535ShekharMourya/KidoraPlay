import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/spelling.dart';
import 'package:kidoraplay/core/theme/app_colors.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/letter_tile.dart';
import 'package:kidoraplay/features/learn_card/spelling_strip.dart';

import '../../helpers/pump_app.dart';

Future<void> pumpStrip(
  WidgetTester tester,
  String word, {
  int? revealed,
  int? highlighted,
  void Function(int)? onTap,
  double width = 560,
}) async {
  final tiles = spellingOf(word);
  await pumpApp(
    tester,
    Center(
      child: SizedBox(
        width: width,
        height: 110,
        child: SpellingStrip(
          tiles: tiles,
          revealed: revealed ?? tiles.length,
          highlighted: highlighted,
          accent: AppColors.abcAccent,
          onTapLetter: onTap ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double scaleOfTile(WidgetTester tester, int index) => tester
    .widget<AnimatedScale>(
      find
          .ancestor(
            of: find.byType(LetterTile).at(index),
            matching: find.byType(AnimatedScale),
          )
          .last,
    )
    .scale;

void main() {
  testWidgets('short words use full-size 96 dp tiles', (tester) async {
    await pumpStrip(tester, 'Cow');
    final size = tester.getSize(find.byType(LetterTile).first);
    expect(size.width, AppSpacing.minTapTarget);
  });

  testWidgets('long words shrink to fit but stay above the minimum',
      (tester) async {
    await pumpStrip(tester, 'Seventy-seven');
    final size = tester.getSize(find.byType(LetterTile).first);
    expect(size.width, lessThan(AppSpacing.minTapTarget));
    expect(
      size.width,
      greaterThanOrEqualTo(AppSpacing.minLetterTile - 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden tiles are invisible and cannot be tapped',
      (tester) async {
    final tapped = <int>[];
    await pumpStrip(tester, 'Hen', revealed: 1, onTap: tapped.add);
    expect(scaleOfTile(tester, 0), 1);
    expect(scaleOfTile(tester, 2), 0);

    await tester.tap(find.byType(LetterTile).at(0));
    await tester.tap(find.byType(LetterTile).at(2), warnIfMissed: false);
    expect(tapped, [0]);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping a revealed letter reports its index', (tester) async {
    final tapped = <int>[];
    await pumpStrip(tester, 'Owl', onTap: tapped.add);
    await tester.tap(find.text('W'));
    expect(tapped, [1]);
    await tester.pumpAndSettle();
  });
}
