import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/learn_card/learn_card_controller.dart';
import 'package:kidoraplay/features/rewards/balloon_party.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  test('every third completed card earns a balloon party', () async {
    final audio = FakeAudio();
    final c = ProviderContainer(
      overrides: testOverrides(
        audio: audio,
        catalog: catalog,
        store: LocalStore.inMemory({
          SettingsKeys.language: 'en',
          'kido.discovered': true,
        }),
      ),
    );
    addTearDown(c.dispose);
    await c.read(contentCatalogProvider.future);

    Future<int> complete(String id) async {
      c.listen(learnCardControllerProvider(id), (_, _) {});
      final card = c.read(learnCardControllerProvider(id).notifier)
        ..attach((section: SectionId.animals, row: null));
      await card.playLesson();
      for (var i = 0; i < 3; i++) {
        await card.tapPicture();
      }
      return c.read(learnCardControllerProvider(id)).parties;
    }

    expect(await complete('cow'), 0);
    expect(await complete('dog'), 0);
    audio.voice.played.clear();
    expect(await complete('cat'), 1);
    expect(
      audio.voice.played,
      contains('assets/audio/en/kido/balloon_party.m4a'),
    );
    expect(audio.voice.played.where((a) => a.contains('/next_one_')), isEmpty);
  });

  testWidgets('pop every balloon: pop, its name, then the party ends', (
    tester,
  ) async {
    final audio = FakeAudio();
    final items = catalog.itemsFor(SectionId.animals).take(3).toList();
    var done = 0;
    await pumpApp(
      tester,
      BalloonParty(items: items, onDone: () => done++, random: math.Random(1)),
      audio: audio,
      catalog: catalog,
      reduceMotion: true, // balloons hold still, easy to tap
    );
    await tester.pump();

    for (final item in items) {
      await tester.tap(find.bySemanticsLabel(item.wordEn));
      await tester.pump();
    }
    expect(audio.sfxNames.where((s) => s == 'pop'), hasLength(3));
    expect(audio.voice.played, [for (final i in items) i.voiceEn]);
    expect(done, 0);
    await tester.pump(AppDurations.balloonLastPop);
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the party ends by itself if the child stops', (tester) async {
    var done = 0;
    await pumpApp(
      tester,
      BalloonParty(
        items: catalog.itemsFor(SectionId.birds).take(4).toList(),
        onDone: () => done++,
      ),
      catalog: catalog,
    );
    await tester.pump(AppDurations.balloonParty);
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
