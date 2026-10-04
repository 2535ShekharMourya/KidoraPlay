import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/parent/parent_area_screen.dart';
import 'package:kidoraplay/features/parent/parent_gate.dart';
import 'package:kidoraplay/features/parent/parent_gate_logic.dart';
import 'package:kidoraplay/features/progress/progress_controller.dart';

import '../../helpers/pump_app.dart';

/// Random with scripted answers: [bools] for nextBool, [ints] for nextInt.
class ScriptedRandom implements Random {
  ScriptedRandom({this.bools = const [], this.ints = const []});

  final List<bool> bools;
  final List<int> ints;
  int _b = 0;
  int _i = 0;
  final _fallback = Random(1);

  @override
  bool nextBool() => _b < bools.length ? bools[_b++] : _fallback.nextBool();

  @override
  int nextInt(int max) =>
      _i < ints.length ? ints[_i++] % max : _fallback.nextInt(max);

  @override
  double nextDouble() => _fallback.nextDouble();
}

/// Hold challenge first, then a number challenge whose answer is 7
/// (nextInt 6 → 1 + 6) with options 7, 2, 4, 9 (before shuffling).
ScriptedRandom holdThenNumber() =>
    ScriptedRandom(bools: [true, false], ints: [6, 1, 3, 8]);

ScriptedRandom numberFirst() =>
    ScriptedRandom(bools: [false, true], ints: [6, 1, 3, 8]);

void main() {
  group('gate challenges', () {
    test('number challenge: 4 different digits including the answer', () {
      final random = Random(42);
      for (var i = 0; i < 200; i++) {
        final c = NumberChallenge.random(random);
        expect(c.answer, inInclusiveRange(1, 9));
        expect(c.options, hasLength(4));
        expect(c.options.toSet(), hasLength(4));
        expect(c.options, contains(c.answer));
        expect(c.isCorrect(c.answer), isTrue);
      }
    });

    test('random picks both kinds of challenge', () {
      final random = Random(7);
      final kinds = {
        for (var i = 0; i < 50; i++) GateChallenge.random(random).runtimeType,
      };
      expect(kinds, {HoldChallenge, NumberChallenge});
    });
  });

  group('ParentGate', () {
    Future<({List<String> events})> pumpGate(
      WidgetTester tester,
      Random random,
    ) async {
      final events = <String>[];
      await pumpApp(
        tester,
        ParentGate(
          random: random,
          onPassed: () => events.add('passed'),
          onCancel: () => events.add('cancelled'),
        ),
      );
      return (events: events);
    }

    testWidgets('holding for 3 seconds passes', (tester) async {
      final (:events) = await pumpGate(tester, holdThenNumber());
      expect(
        find.text('Press and hold the button for 3 seconds'),
        findsOneWidget,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hold')),
      );
      await tester.pump(); // starts the animation clock
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(events, ['passed']);
      await gesture.up();
    });

    testWidgets('letting go too early does not pass', (tester) async {
      final (:events) = await pumpGate(tester, holdThenNumber());
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hold')),
      );
      await tester.pump(); // starts the animation clock
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
      expect(events, isEmpty);
    });

    testWidgets('number word: the right digit passes', (tester) async {
      final (:events) = await pumpGate(tester, numberFirst());
      expect(find.text('Tap the number seven'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gate-option-7')));
      expect(events, ['passed']);
    });

    testWidgets('a wrong digit gives a new challenge, not a pass', (
      tester,
    ) async {
      final (:events) = await pumpGate(tester, numberFirst());
      final wrong = [2, 4, 9].firstWhere(
        (n) => find.byKey(ValueKey('gate-option-$n')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(ValueKey('gate-option-$wrong')));
      await tester.pump();
      expect(events, isEmpty);
      expect(find.text('Not quite. Here is a new one.'), findsOneWidget);
      // The next challenge from the script is the hold task.
      expect(find.text('Hold'), findsOneWidget);
    });

    testWidgets('cancel leaves', (tester) async {
      final (:events) = await pumpGate(tester, holdThenNumber());
      await tester.tap(find.text('Cancel'));
      expect(events, ['cancelled']);
    });
  });

  group('ParentAreaScreen', () {
    late ContentCatalog catalog;
    setUpAll(() async => catalog = await loadTestCatalog());

    Future<ProviderContainer> openUnlocked(
      WidgetTester tester, {
      LocalStore? store,
    }) async {
      await pumpApp(
        tester,
        const ParentAreaScreen(),
        catalog: catalog,
        store: store,
      );
      // Pass whichever gate appears.
      if (find.text('Hold').evaluate().isNotEmpty) {
        final g = await tester.startGesture(
          tester.getCenter(find.text('Hold')),
        );
        await tester.pump(); // starts the animation clock
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 100));
        await g.up();
      } else {
        final prompt = tester
            .widget<Text>(find.textContaining('Tap the number'))
            .data!;
        final word = prompt.split(' ').last;
        const words = [
          'one', 'two', 'three', 'four', 'five', //
          'six', 'seven', 'eight', 'nine',
        ];
        await tester.tap(
          find.byKey(ValueKey('gate-option-${words.indexOf(word) + 1}')),
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('Parents'), findsOneWidget);
      return ProviderScope.containerOf(
        tester.element(find.byType(ParentAreaScreen)),
      );
    }

    Future<void> scrollTo(
      WidgetTester tester,
      Finder finder, {
      double delta = 120,
    }) async {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('starts locked behind the gate', (tester) async {
      await pumpApp(tester, const ParentAreaScreen(), catalog: catalog);
      expect(find.text('Grown-ups only'), findsOneWidget);
      expect(find.text('Class'), findsNothing);
    });

    testWidgets('class, language and switches change the settings', (
      tester,
    ) async {
      final c = await openUnlocked(tester);

      await tester.tap(find.text('Nursery'));
      await tester.pump();
      expect(c.read(settingsProvider).level, Level.nursery);

      await tester.tap(find.text('हिंदी'));
      await tester.pump();
      expect(c.read(settingsProvider).language, LanguageMode.hi);

      await scrollTo(tester, find.text('Background music'));
      await tester.tap(find.text('Background music'));
      await tester.pump();
      expect(c.read(settingsProvider).musicEnabled, isTrue);

      await scrollTo(tester, find.text('Vibration'));
      await tester.tap(find.text('Vibration'));
      await tester.pump();
      expect(c.read(settingsProvider).vibrationEnabled, isFalse);

      await scrollTo(tester, find.text('Sound'), delta: -120);
      await tester.tap(find.text('Sound'));
      await tester.pump();
      expect(c.read(settingsProvider).soundEnabled, isFalse);
    });

    testWidgets('reset progress asks first, then clears stickers', (
      tester,
    ) async {
      final c = await openUnlocked(
        tester,
        store: LocalStore.inMemory({
          SettingsKeys.language: 'en',
          'progress.learned': ['cow', 'hen'],
        }),
      );
      await scrollTo(tester, find.text('2 stickers collected'));
      expect(find.text('2 stickers collected'), findsOneWidget);

      await tester.tap(find.text('Reset progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.read(progressProvider).learned, hasLength(2));

      await tester.tap(find.text('Reset progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(c.read(progressProvider).learned, isEmpty);
      expect(find.text('0 stickers collected'), findsOneWidget);
    });

    testWidgets('shows the privacy promise', (tester) async {
      await openUnlocked(tester);
      await scrollTo(tester, find.text('Licences and credits'));
      expect(find.textContaining('collects no personal data'), findsOneWidget);
      expect(find.text('Licences and credits'), findsOneWidget);
    });
  });
}
