import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/widgets/big_back_button.dart';
import 'package:kidoraplay/core/widgets/bouncy_button.dart';
import 'package:kidoraplay/features/learn_card/learn_card_controller.dart';
import 'package:kidoraplay/features/progress/progress_controller.dart';
import 'package:kidoraplay/features/progress/sticker_book_screen.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

const row1 = (section: SectionId.numbers, row: 1);

Finder button(String label) => find.byWidgetPredicate(
  (w) => w is BouncyButton && w.semanticLabel == label,
);

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  Future<ProviderContainer> containerWith({
    LocalStore? store,
    FakeAudio? audio,
  }) async {
    final c = ProviderContainer(
      overrides: testOverrides(catalog: catalog, store: store, audio: audio),
    );
    addTearDown(c.dispose);
    await c.read(contentCatalogProvider.future);
    return c;
  }

  group('ProgressNotifier', () {
    test('learning an item earns its sticker once, saved on device', () async {
      final store = LocalStore.inMemory({SettingsKeys.language: 'en'});
      final c = await containerWith(store: store);
      final cow = catalog.itemById('cow')!;
      const scope = (section: SectionId.animals, row: null);

      final first = await c
          .read(progressProvider.notifier)
          .markLearned(cow, scope);
      expect(first.newSticker, isTrue);
      final again = await c
          .read(progressProvider.notifier)
          .markLearned(cow, scope);
      expect(again.newSticker, isFalse);

      final c2 = await containerWith(store: store);
      expect(c2.read(progressProvider).isLearned('cow'), isTrue);
    });

    test(
      'completing a set is reported only for the last missing item',
      () async {
        final c = await containerWith();
        final notifier = c.read(progressProvider.notifier);
        final numbers = catalog
            .itemsFor(SectionId.numbers)
            .where((i) => i.number! <= 10)
            .toList();

        for (final item in numbers.take(9)) {
          expect(
            (await notifier.markLearned(item, row1)).completedScope,
            isFalse,
          );
        }
        expect(
          (await notifier.markLearned(numbers.last, row1)).completedScope,
          isTrue,
        );
        // Already complete: no second celebration.
        expect(
          (await notifier.markLearned(numbers.first, row1)).completedScope,
          isFalse,
        );
      },
    );

    test('section progress counts stickers at the selected class', () async {
      final c = await containerWith(
        store: LocalStore.inMemory({
          SettingsKeys.level: 'nursery',
          'progress.learned': ['one', 'two', 'fifty'],
        }),
      );
      // Nursery sees 1–20, so "fifty" does not count here.
      expect(c.read(sectionProgressProvider(SectionId.numbers)), (
        learned: 2,
        total: 20,
      ));
    });
  });

  group('learn card rewards', () {
    test('finding the picture earns a sticker', () async {
      final audio = FakeAudio();
      final c = await containerWith(audio: audio);
      c.listen(learnCardControllerProvider('cow'), (_, _) {});
      final card = c.read(learnCardControllerProvider('cow').notifier)
        ..attach((section: SectionId.animals, row: null));
      await card.playLesson();
      await card.tapPicture();

      expect(c.read(learnCardControllerProvider('cow')).stickers, 1);
      expect(c.read(learnCardControllerProvider('cow')).completions, 0);
      expect(c.read(progressProvider).isLearned('cow'), isTrue);
    });

    test('the last item of a set brings the big celebration', () async {
      final audio = FakeAudio();
      final c = await containerWith(
        audio: audio,
        store: LocalStore.inMemory({
          SettingsKeys.language: 'en',
          'progress.learned': [
            'one', 'two', 'three', 'four', 'five', //
            'six', 'seven', 'eight', 'nine',
          ],
        }),
      );
      c.listen(learnCardControllerProvider('ten'), (_, _) {});
      final card = c.read(learnCardControllerProvider('ten').notifier)
        ..attach(row1);
      await card.playLesson();
      audio.voice.played.clear();
      await card.tapPicture();

      expect(c.read(learnCardControllerProvider('ten')).completions, 1);
      expect(audio.sfxNames, ['cheer', 'sparkle']);
      // "You learned" + "ten" + "Numbers".
      expect(audio.voice.played.sublist(audio.voice.played.length - 3), [
        'assets/audio/en/kido/you_learned.m4a',
        'assets/audio/en/ten.m4a',
        'assets/audio/en/sections/numbers.m4a',
      ]);
    });
  });

  testWidgets('sticker book: stars, section tabs, and names on tap', (
    tester,
  ) async {
    final audio = FakeAudio();
    await pumpApp(
      tester,
      const StickerBookScreen(),
      audio: audio,
      catalog: catalog,
      store: LocalStore.inMemory({
        SettingsKeys.language: 'en',
        'progress.learned': ['one', 'two'],
      }),
    );
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // First the section choice; two of the 100 numbers are collected.
    expect(find.text('2/100'), findsWidgets);
    await tester.tap(button('Numbers 2/100'));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(button('Two'));
    await tester.pump();
    expect(audio.voice.played, ['assets/audio/en/two.m4a']);

    // Back to the section choice, then the ABC stickers.
    await tester.tap(find.byType(BigBackButton));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(button('ABC 0/26'));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(button('Apple'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
