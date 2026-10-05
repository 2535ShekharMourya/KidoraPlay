import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kidoraplay/app.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/core/router/app_router.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/home/home_screen.dart';
import 'package:kidoraplay/features/learn_card/learn_card_screen.dart';
import 'package:kidoraplay/features/tracing/trace_controller.dart';
import 'package:kidoraplay/features/tracing/trace_logic.dart';
import 'package:kidoraplay/features/tracing/trace_screen.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late ContentCatalog catalog;
  late TraceGuides guides;
  setUpAll(() async {
    catalog = await loadTestCatalog();
    guides = await loadTraceGuides(rootBundle);
  });

  group('guides', () {
    test('every capital letter and digit can be traced', () {
      for (final g in [
        ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
        ...'0123456789'.split(''),
      ]) {
        final strokes = guides.strokesOf(g);
        expect(strokes, isNotNull, reason: g);
        for (final s in strokes!) {
          expect(s.length, greaterThan(2), reason: g);
          for (final p in s) {
            expect(p.dx, inInclusiveRange(-0.01, 1.01), reason: g);
            expect(p.dy, inInclusiveRange(-0.01, 1.01), reason: g);
          }
        }
      }
    });

    test('letters trace their capital, numbers each digit', () {
      final apple = catalog.itemsFor(SectionId.abc).first;
      expect(guides.glyphsFor(apple), ['A']);
      final n21 = catalog
          .itemsFor(SectionId.numbers)
          .firstWhere((i) => i.number == 21);
      expect(guides.glyphsFor(n21), ['2', '1']);
      expect(
        guides.glyphsFor(catalog.itemsFor(SectionId.animals).first),
        isNull,
      );
    });

    test('resampled points are evenly spaced', () {
      final s = resample(const [Offset(0, 0), Offset(1, 0)]);
      expect(s.length, 51);
      for (var i = 1; i < s.length; i++) {
        expect((s[i] - s[i - 1]).distance, closeTo(traceStep, 1e-9));
      }
    });
  });

  group('rules', () {
    final line = [
      resample(const [Offset(0.5, 0.1), Offset(0.5, 0.9)]),
    ];
    final two = [line, line];

    test('the finger pulls the stroke along when it is near', () {
      var (at, step) = TraceRules.move(
        [line],
        const TracePosition(),
        0,
        const Offset(0.52, 0.2),
      );
      expect(step, TraceStep.progress);
      expect(at.progress, greaterThan(0));
      final before = at.progress;
      (at, step) = TraceRules.move([line], at, 0, const Offset(0.5, 0.26));
      expect(at.progress, greaterThan(before));
    });

    test('far from the path, or jumping ahead, does nothing', () {
      final (at1, s1) = TraceRules.move(
        [line],
        const TracePosition(),
        0,
        const Offset(0.9, 0.5),
      );
      expect(s1, TraceStep.none);
      expect(at1, const TracePosition());
      // The end of the stroke is too far ahead to count.
      final (at2, s2) = TraceRules.move(
        [line],
        const TracePosition(),
        0,
        const Offset(0.5, 0.9),
      );
      expect(s2, TraceStep.none);
      expect(at2.progress, 0);
    });

    test('strokes, glyphs, then the whole word finish', () {
      var at = const TracePosition();
      final steps = <TraceStep>[];
      for (var g = 0; g < 2; g++) {
        for (var y = 0.1; y <= 0.9001; y += 0.05) {
          final (next, step) = TraceRules.move(two, at, g, Offset(0.5, y));
          at = next;
          if (step != TraceStep.none && step != TraceStep.progress) {
            steps.add(step);
          }
        }
      }
      expect(steps, [TraceStep.glyphDone, TraceStep.allDone]);
    });
  });

  testWidgets('learn card pencil → trace A with a finger → cheer', (
    tester,
  ) async {
    final audio = FakeAudio();
    useLandscapePhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(audio: audio, catalog: catalog),
          traceGuidesProvider.overrideWith((ref) async => guides),
        ],
        child: const KidoraApp(),
      ),
    );
    await tester.pump(AppDurations.splash);
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    final context = tester.element(find.byType(HomeScreen));
    GoRouter.of(context)
        .go(AppRoutes.learn((section: SectionId.abc, row: null), 'a_apple'));
    await settle(tester);
    expect(find.byType(LearnCardScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Write it'));
    await settle(tester);
    expect(find.byType(TraceScreen), findsOneWidget);
    expect(audio.voice.played, contains('assets/audio/en/kido/lets_write.m4a'));
    expect(audio.voice.played, contains('assets/audio/letters/a.m4a'));

    // Trace every stroke of A, finger down to finger up.
    final board = tester.getRect(find.byType(TraceBoard));
    final box = board.height;
    for (final stroke in guides.strokesOf('A')!) {
      final g = await tester.startGesture(board.topLeft + stroke.first * box);
      for (final p in stroke.skip(1)) {
        await g.moveTo(board.topLeft + p * box);
      }
      await g.up();
      await tester.pump();
    }
    await settle(tester);

    final element = tester.element(find.byType(TraceScreen));
    final state = ProviderScope.containerOf(element)
        .read(traceControllerProvider('a_apple'));
    expect(state.finished, isTrue);
    expect(state.celebrations, 1);
    expect(find.bySemanticsLabel('Write again'), findsOneWidget);
    expect(audio.voice.played, contains('assets/audio/en/kido/you_wrote.m4a'));

    // Write it again: back to the first stroke.
    await tester.tap(find.bySemanticsLabel('Write again'));
    await settle(tester);
    expect(
      ProviderScope.containerOf(element)
          .read(traceControllerProvider('a_apple'))
          .finished,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
