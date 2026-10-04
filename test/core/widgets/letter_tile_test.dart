import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/spelling.dart';
import 'package:kidoraplay/core/theme/app_colors.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/bouncy_button.dart';
import 'package:kidoraplay/core/widgets/letter_tile.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('voiced letter is a tappable tile', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: LetterTile(
          tile: const SpellingTile('A'),
          accent: AppColors.abcAccent,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.byType(LetterTile));
    expect(taps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('hyphen and space are shown but not tappable', (tester) async {
    await pumpApp(
      tester,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final tile in spellingOf('Ice-Cream X'))
            LetterTile(tile: tile, accent: AppColors.abcAccent, size: 48),
        ],
      ),
    );
    expect(find.text('-'), findsOneWidget);
    // 9 letters are buttons; the hyphen and space are not.
    expect(find.byType(BouncyButton), findsNWidgets(9));
  });

  testWidgets('highlighted tile grows and fills with the accent',
      (tester) async {
    Future<void> pump({required bool highlighted}) => pumpApp(
          tester,
          Center(
            child: LetterTile(
              tile: const SpellingTile('P'),
              accent: AppColors.abcAccent,
              highlighted: highlighted,
            ),
          ),
        );

    await pump(highlighted: false);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

    await pump(highlighted: true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      AppScale.highlighted,
    );
    final box = tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer))
        .decoration! as BoxDecoration;
    expect(box.color, AppColors.abcAccent);
  });
}
