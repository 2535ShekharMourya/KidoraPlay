import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/particle_burst.dart';

import '../../helpers/pump_app.dart';

Finder burstPaint() => find.descendant(
  of: find.byType(ParticleBurst),
  matching: find.byType(CustomPaint),
);

void main() {
  for (final style in BurstStyle.values) {
    testWidgets('${style.name}: fire shows particles, then clears', (
      tester,
    ) async {
      final controller = BurstController();
      addTearDown(controller.dispose);
      await pumpApp(
        tester,
        ParticleBurst(controller: controller, style: style, random: Random(1)),
      );
      expect(burstPaint(), findsNothing);

      controller.fire();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(burstPaint(), findsOneWidget);

      await tester.pump(AppDurations.confetti);
      await tester.pump();
      expect(burstPaint(), findsNothing);
    });
  }

  testWidgets('never blocks taps on the child', (tester) async {
    final controller = BurstController();
    addTearDown(controller.dispose);
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: ParticleBurst(
          controller: controller,
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('tap'),
          ),
        ),
      ),
    );
    controller.fire();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('tap'));
    expect(taps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: no particles', (tester) async {
    final controller = BurstController();
    addTearDown(controller.dispose);
    await pumpApp(
      tester,
      ParticleBurst(controller: controller, style: BurstStyle.confetti),
      reduceMotion: true,
    );
    controller.fire();
    await tester.pump();
    expect(burstPaint(), findsNothing);
  });
}
