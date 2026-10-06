import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/learn_card/learn_card_controller.dart';
import 'package:kidoraplay/features/path/daily_path.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  group('the day\'s steps', () {
    test('two cards, a game, a card, then tracing', () {
      final steps = buildPath(
        catalog: catalog,
        level: Level.nursery,
        learned: const {},
        day: '2026-10-06',
      );
      expect(steps.map((s) => s.kind), [
        PathKind.learn,
        PathKind.learn,
        PathKind.game,
        PathKind.learn,
        PathKind.trace,
      ]);
      // Three different cards from three different sections.
      final sections = {
        for (final s in steps.where((s) => s.kind == PathKind.learn))
          catalog.itemById(s.ref)!.section,
      };
      expect(sections, hasLength(3));
    });

    test('babies end with a toy and never get the Letters game', () {
      for (var d = 1; d <= 20; d++) {
        final steps = buildPath(
          catalog: catalog,
          level: Level.baby,
          learned: const {},
          day: '2026-10-${d.toString().padLeft(2, '0')}',
        );
        expect(steps.last.kind, PathKind.toy);
        expect(steps.where((s) => s.key == 'game:letters'), isEmpty);
        for (final s in steps.where((s) => s.kind == PathKind.learn)) {
          expect(catalog.itemById(s.ref)!.isForLevel(Level.baby), isTrue);
        }
      }
    });

    test('same day, same path; another day, another path', () {
      List<String> on(String day) => [
        for (final s in buildPath(
          catalog: catalog,
          level: Level.lkg,
          learned: const {},
          day: day,
        ))
          s.key,
      ];
      expect(on('2026-10-06'), on('2026-10-06'));
      expect(on('2026-10-06'), isNot(on('2026-10-07')));
    });

    test('prefers words the child has not learned yet', () {
      final animals = catalog.itemsFor(SectionId.animals).map((i) => i.id);
      final steps = buildPath(
        catalog: catalog,
        level: Level.lkg,
        learned: {...animals.skip(1)}, // all animals but one
        day: '2026-10-06',
      );
      for (final s in steps.where((s) => s.kind == PathKind.learn)) {
        final item = catalog.itemById(s.ref)!;
        if (item.section == SectionId.animals) {
          expect(s.ref, animals.first);
        }
      }
    });
  });

  group('ticking off', () {
    late DateTime now;
    late LocalStore store;

    ProviderContainer open() {
      final c = ProviderContainer(
        overrides: [
          ...testOverrides(audio: FakeAudio(), catalog: catalog, store: store),
          pathClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      now = DateTime(2026, 10, 6, 9);
      store = LocalStore.inMemory({
        SettingsKeys.language: 'en',
        SettingsKeys.level: 'nursery',
        'kido.discovered': true,
      });
    });

    test('steps tick off, are saved, and five make a trophy', () async {
      var c = open();
      await c.read(contentCatalogProvider.future);
      final steps = c.read(dailyPathProvider).steps;
      expect(steps, hasLength(5));
      await pumpEventQueue();

      // Something that isn't a step changes nothing.
      await c
          .read(dailyPathProvider.notifier)
          .completed(const PathStep(PathKind.game, 'nope'));
      expect(c.read(dailyPathProvider).done, isEmpty);

      await c.read(dailyPathProvider.notifier).completed(steps[0]);
      await c.read(dailyPathProvider.notifier).completed(steps[1]);
      expect(c.read(dailyPathProvider).current, 2);

      // Closing and opening the app keeps today's path and progress.
      c.dispose();
      c = open();
      await c.read(contentCatalogProvider.future);
      expect(
        [for (final s in c.read(dailyPathProvider).steps) s.key],
        [for (final s in steps) s.key],
      );
      expect(c.read(dailyPathProvider).current, 2);

      for (final s in steps.skip(2)) {
        await c.read(dailyPathProvider.notifier).completed(s);
      }
      final done = c.read(dailyPathProvider);
      expect(done.finished, isTrue);
      expect(done.trophies, 1);
      expect(done.celebrations, 1);

      // Tomorrow: a fresh path; the trophy stays. Nothing is lost for a
      // missed day (no streaks).
      now = DateTime(2026, 10, 8, 9);
      c.dispose();
      c = open();
      await c.read(contentCatalogProvider.future);
      expect(c.read(dailyPathProvider).done, isEmpty);
      expect(c.read(dailyPathProvider).trophies, 1);
    });

    test('finishing a card ticks off its step', () async {
      final c = open();
      await c.read(contentCatalogProvider.future);
      final step = c
          .read(dailyPathProvider)
          .steps
          .firstWhere((s) => s.kind == PathKind.learn);
      final item = catalog.itemById(step.ref)!;
      c.listen(learnCardControllerProvider(item.id), (_, _) {});
      final card = c.read(learnCardControllerProvider(item.id).notifier)
        ..attach((section: item.section, row: null));
      await card.playLesson();
      for (var i = 0; i < 3; i++) {
        await card.tapPicture();
      }
      await pumpEventQueue();
      expect(c.read(dailyPathProvider).isDone(step), isTrue);
    });
  });
}
