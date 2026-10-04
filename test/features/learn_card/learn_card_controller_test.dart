import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/learn_card/learn_card_controller.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  late FakeAudio audio;
  late ProviderContainer container;

  Future<void> setUpContainer({LocalStore? store}) async {
    audio = FakeAudio();
    container = ProviderContainer(
      overrides: testOverrides(
        audio: audio,
        catalog: catalog,
        store: store,
      ),
    );
    addTearDown(container.dispose);
    await container.read(contentCatalogProvider.future);
    // Keep the auto-dispose controller alive for the test.
    container.listen(learnCardControllerProvider('cow'), (_, _) {});
    container.listen(learnCardControllerProvider('twenty_one'), (_, _) {});
  }

  LearnCardController controller(String id) =>
      container.read(learnCardControllerProvider(id).notifier);
  LearnCardState stateOf(String id) =>
      container.read(learnCardControllerProvider(id));

  test('animal lesson: sound, word, letters, word, then celebrate', () async {
    await setUpContainer();
    await controller('cow').playLesson();

    expect(audio.voice.played, [
      'assets/audio/animals/cow.m4a',
      'assets/audio/en/cow.m4a',
      'assets/audio/letters/c.m4a',
      'assets/audio/letters/o.m4a',
      'assets/audio/letters/w.m4a',
      'assets/audio/en/cow.m4a',
    ]);
    expect(audio.sfxNames, ['cheer']);
    final s = stateOf('cow');
    expect(s.revealed, 3);
    expect(s.highlighted, isNull);
    expect(s.celebrations, 1);
    expect(s.playing, isFalse);
  });

  test('picture reacts while its sound plays', () async {
    await setUpContainer();
    audio.voice.holdPlayback = true;
    final lesson = controller('cow').playLesson();
    await pumpEventQueue();
    expect(stateOf('cow').reacting, isTrue);

    audio.voice.finishCurrent(); // sound done → word starts
    await pumpEventQueue();
    expect(stateOf('cow').reacting, isFalse);

    audio.voice.holdPlayback = false;
    audio.voice.finishCurrent();
    await lesson;
  });

  test('tiles appear one by one as letters are spoken', () async {
    await setUpContainer();
    audio.voice.holdPlayback = true;
    final lesson = controller('cow').playLesson();
    await pumpEventQueue();
    audio.voice.finishCurrent(); // sound
    await pumpEventQueue();
    audio.voice.finishCurrent(); // word
    await pumpEventQueue();
    expect(stateOf('cow').highlighted, 0);
    expect(stateOf('cow').revealed, 1);

    audio.voice.finishCurrent(); // C
    await pumpEventQueue();
    expect(stateOf('cow').highlighted, 1);
    expect(stateOf('cow').revealed, 2);

    audio.voice.holdPlayback = false;
    audio.voice.finishCurrent();
    await lesson;
    expect(stateOf('cow').revealed, 3);
  });

  test('hyphen is shown but not spoken', () async {
    await setUpContainer();
    await controller('twenty_one').playLesson();
    final letters = audio.voice.played
        .where((a) => a.contains('/letters/'))
        .map((a) => a.split('/').last.split('.').first)
        .join();
    expect(letters, 'twentyone');
    expect(stateOf('twenty_one').revealed, 'TWENTY-ONE'.length);
  });

  test('"both" says the word in English then Hindi', () async {
    await setUpContainer(
      store: LocalStore.inMemory({SettingsKeys.language: 'both'}),
    );
    await controller('cow').playLesson();
    expect(audio.voice.played.sublist(1, 3), [
      'assets/audio/en/cow.m4a',
      'assets/audio/hi/cow.m4a',
    ]);
  });

  test('tapping a letter stops the lesson and says that letter', () async {
    await setUpContainer();
    audio.voice.holdPlayback = true;
    final lesson = controller('cow').playLesson();
    await pumpEventQueue();

    final tap = controller('cow').tapLetter(2);
    await pumpEventQueue();
    expect(stateOf('cow').highlighted, 2);
    expect(stateOf('cow').revealed, 3);
    audio.voice.finishCurrent();
    await tap;
    await lesson;

    expect(audio.voice.played.last, 'assets/audio/letters/w.m4a');
    expect(stateOf('cow').highlighted, isNull);
    // The interrupted lesson did not celebrate.
    expect(audio.sfx.played, isEmpty);
  });

  testWidgets('with sound off the lesson still runs silently',
      (tester) async {
    await setUpContainer(
      store: LocalStore.inMemory({SettingsKeys.sound: false}),
    );
    final lesson = controller('cow').playLesson();
    // sound + word + 3 letters + word, each a silent beat.
    await tester.pump(AppDurations.silentSegment * 7);
    await lesson;
    expect(audio.voice.played, isEmpty);
    expect(stateOf('cow').revealed, 3);
    expect(stateOf('cow').celebrations, 1);
  });

  test('leaving the screen stops the voice', () async {
    await setUpContainer();
    final sub =
        container.listen(learnCardControllerProvider('hen'), (_, _) {});
    audio.voice.holdPlayback = true;
    final lesson = container
        .read(learnCardControllerProvider('hen').notifier)
        .playLesson();
    await pumpEventQueue();
    expect(audio.voice.isPlaying, isTrue);

    sub.close(); // Screen closed: the auto-dispose controller goes away.
    await pumpEventQueue();
    await lesson;
    expect(audio.voice.stops, greaterThanOrEqualTo(1));
    expect(container.read(audioServiceProvider).isSpeaking, isFalse);
  });
}
