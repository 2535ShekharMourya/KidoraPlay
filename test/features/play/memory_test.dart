import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/games/quiz_controller.dart';
import 'package:kidoraplay/features/play/memory_controller.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  Future<ProviderContainer> container(String level) async {
    final c = ProviderContainer(
      overrides: [
        ...testOverrides(
          audio: FakeAudio(),
          catalog: catalog,
          store: LocalStore.inMemory({
            SettingsKeys.language: 'en',
            SettingsKeys.level: level,
          }),
        ),
        quizRandomProvider.overrideWithValue(math.Random(4)),
      ],
    );
    addTearDown(c.dispose);
    await c.read(contentCatalogProvider.future);
    c.listen(memoryControllerProvider, (_, _) {});
    return c;
  }

  (int, int) pairOf(MemoryState s, {bool same = true}) {
    for (var i = 0; i < s.cards.length; i++) {
      for (var j = i + 1; j < s.cards.length; j++) {
        if ((s.cards[i].item.id == s.cards[j].item.id) == same) return (i, j);
      }
    }
    throw StateError('no pair');
  }

  test('pairs by class, limited by what fits the screen', () async {
    final nursery = await container('nursery');
    nursery.read(memoryControllerProvider.notifier).start(maxCards: 12);
    expect(nursery.read(memoryControllerProvider).cards, hasLength(6));

    final ukg = await container('ukg');
    ukg.read(memoryControllerProvider.notifier).start(maxCards: 8);
    final cards = ukg.read(memoryControllerProvider).cards;
    expect(cards, hasLength(8)); // 6 pairs wanted, 4 fit
    // Every picture appears exactly twice.
    final ids = cards.map((c) => c.item.id).toList();
    for (final id in ids) {
      expect(ids.where((x) => x == id), hasLength(2));
    }
  });

  testWidgets('two the same stay up; two different turn back', (tester) async {
    final c = await container('nursery');
    final game = c.read(memoryControllerProvider.notifier)..start();
    MemoryState s() => c.read(memoryControllerProvider);

    final (a, b) = pairOf(s(), same: false);
    game
      ..tap(a)
      ..tap(b);
    expect(s().cards[a].faceUp && s().cards[b].faceUp, isTrue);
    expect(s().busy, isTrue);
    game.tap(a); // waiting: ignored, no change
    await tester.pump(AppDurations.memoryLook);
    expect(s().cards[a].faceUp || s().cards[b].faceUp, isFalse);
    expect(s().busy, isFalse);

    final (x, y) = pairOf(s());
    game
      ..tap(x)
      ..tap(y);
    expect(s().cards[x].matched && s().cards[y].matched, isTrue);
    expect(s().matches, 1);
  });

  testWidgets('all pairs found: celebration', (tester) async {
    final c = await container('nursery');
    final game = c.read(memoryControllerProvider.notifier)..start();
    MemoryState s() => c.read(memoryControllerProvider);
    while (!s().finished) {
      final remaining = [
        for (var i = 0; i < s().cards.length; i++)
          if (!s().cards[i].matched) i,
      ];
      final i = remaining.first;
      final j = remaining.firstWhere(
        (k) => k != i && s().cards[k].item.id == s().cards[i].item.id,
      );
      game
        ..tap(i)
        ..tap(j);
    }
    expect(s().games, 1);
    await tester.pump(const Duration(seconds: 5));
  });
}
