import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/idle_float.dart';
import 'package:kidoraplay/core/widgets/pop_in.dart';
import 'package:kidoraplay/core/widgets/section_background.dart';

import '../../helpers/pump_app.dart';

double opacityOf(WidgetTester tester, Finder child) => tester
    .widget<Opacity>(find.ancestor(of: child, matching: find.byType(Opacity)))
    .opacity;

void main() {
  group('PopIn', () {
    testWidgets('items appear one after another', (tester) async {
      await pumpApp(
        tester,
        const Row(
          children: [
            PopIn(child: Text('a')),
            PopIn(index: 3, child: Text('b')),
          ],
        ),
      );
      await tester.pump(AppDurations.staggerStep);
      await tester.pump(const Duration(milliseconds: 60));
      expect(opacityOf(tester, find.text('a')), greaterThan(0));
      expect(opacityOf(tester, find.text('b')), 0);

      await tester.pumpAndSettle();
      expect(opacityOf(tester, find.text('b')), 1);
    });

    testWidgets('reduced motion shows items immediately', (tester) async {
      await pumpApp(
        tester,
        const PopIn(index: 5, child: Text('a')),
        reduceMotion: true,
      );
      expect(opacityOf(tester, find.text('a')), 1);
    });
  });

  group('IdleFloat', () {
    testWidgets('moves gently, and not at all with reduced motion', (
      tester,
    ) async {
      await pumpApp(tester, const Center(child: IdleFloat(child: Text('a'))));
      final start = tester.getCenter(find.text('a'));
      await tester.pump(AppDurations.idleFloat ~/ 4);
      final moved = tester.getCenter(find.text('a'));
      expect((moved.dy - start.dy).abs(), greaterThan(1));
      expect(
        (moved.dy - start.dy).abs(),
        lessThanOrEqualTo(AppScale.idleFloatOffset + 0.01),
      );

      await pumpApp(
        tester,
        const Center(child: IdleFloat(child: Text('b'))),
        reduceMotion: true,
      );
      final still = tester.getCenter(find.text('b'));
      await tester.pump(AppDurations.idleFloat ~/ 4);
      expect(tester.getCenter(find.text('b')), still);
    });
  });

  group('SectionBackground', () {
    for (final section in [null, ...SectionId.values]) {
      testWidgets(
        'paints ${section?.name ?? 'home'} and keeps child tappable',
        (tester) async {
          var taps = 0;
          await pumpApp(
            tester,
            SectionBackground(
              section: section,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('go'),
                ),
              ),
            ),
          );
          await tester.pump(AppDurations.backgroundLoop ~/ 3);
          await tester.tap(find.text('go'));
          expect(taps, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('reduced motion: background is static', (tester) async {
      await pumpApp(
        tester,
        const SectionBackground(section: SectionId.animals, child: SizedBox()),
        reduceMotion: true,
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
