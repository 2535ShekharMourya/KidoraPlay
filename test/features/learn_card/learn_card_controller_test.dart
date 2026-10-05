import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/kido/hint_timer.dart';
import 'package:kidoraplay/features/learn_card/learn_card_controller.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

const kido = 'assets/audio/en/kido';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  late FakeAudio audio;
  late ProviderContainer container;

  Future<void> setUpContainer({LocalStore? store}) async {
    audio = FakeAudio();
    container = ProviderContainer(
      overrides: testOverrides(audio: audio, catalog: catalog, store: store),
    );
    addTearDown(container.dispose);
    await container.read(contentCatalogProvider.future);
  }

  LearnCardController controller(String id) {
    // Keep the auto-dispose controller alive for the test.
    container.listen(learnCardControllerProvider(id), (_, _) {});
    return container.read(learnCardControllerProvider(id).notifier);
  }

  LearnCardState stateOf(String id) =>
      container.read(learnCardControllerProvider(id));

  /// With held playback, finishes clips until [clip] is the one playing.
  Future<void> playUntil(String clip) async {
    for (var i = 0; i < 60 && audio.voice.played.lastOrNull != clip; i++) {
      audio.voice.finishCurrent();
      await pumpEventQueue();
    }
    expect(audio.voice.played.last, clip);
  }

  group('I do', () {
    test(
      'animal: look, name, listen + sound, fact, spell, say with me',
      () async {
        await setUpContainer();
        await controller('cow').playLesson();

        final played = audio.voice.played;
        expect(played.sublist(0, played.length - 1), [
          '$kido/look.m4a',
          'assets/audio/en/cow.m4a',
          '$kido/listen_to_the.m4a',
          'assets/audio/en/cow.m4a',
          'assets/audio/animals/cow.m4a',
          'assets/audio/en/cow_fact.m4a',
          'assets/audio/letters/c.m4a',
          'assets/audio/letters/o.m4a',
          'assets/audio/letters/w.m4a',
          '$kido/say_with_me.m4a',
          'assets/audio/en/cow.m4a',
        ]);
        expect(played.last, startsWith('$kido/yay_'));
        final s = stateOf('cow');
        expect(s.phase, LessonPhase.youDo);
        expect(s.revealed, 3);
        expect(s.cheers, 1);
        expect(s.celebrations, 0); // celebrated only after the child's turn
      },
    );

    test('ABC says "A for Apple!"', () async {
      await setUpContainer();
      await controller('a_apple').playLesson();
      expect(audio.voice.played.sublist(0, 5), [
        '$kido/look.m4a',
        'assets/audio/letters/a.m4a',
        '$kido/for.m4a',
        'assets/audio/en/a_apple.m4a',
        'assets/audio/en/a_apple_fact.m4a',
      ]);
    });

    test(
      'small numbers: "Let\'s count!" 1, 2, 3 with the count shown',
      () async {
        await setUpContainer();
        final counts = <int>[];
        container.listen(
          learnCardControllerProvider('three'),
          (_, next) => counts.add(next.counted),
        );
        await controller('three').playLesson();
        expect(audio.voice.played.sublist(0, 7), [
          '$kido/look.m4a',
          'assets/audio/en/three.m4a',
          '$kido/lets_count.m4a',
          'assets/audio/en/one.m4a',
          'assets/audio/en/two.m4a',
          'assets/audio/en/three.m4a',
          'assets/audio/en/three.m4a',
        ]);
        expect(counts.toSet().containsAll([1, 2, 3]), isTrue);
        expect(stateOf('three').counted, 0);
      },
    );

    test('big numbers skip counting; hyphen is shown but not spoken', () async {
      await setUpContainer();
      await controller('twenty_one').playLesson();
      expect(audio.voice.played, isNot(contains('$kido/lets_count.m4a')));
      final letters = audio.voice.played
          .where((a) => a.contains('/letters/'))
          .map((a) => a.split('/').last.split('.').first)
          .join();
      expect(letters, 'twentyone');
      expect(stateOf('twenty_one').revealed, 'TWENTY-ONE'.length);
    });

    test('"both": words in English then Hindi, Kido talks in Hindi', () async {
      await setUpContainer(
        store: LocalStore.inMemory({SettingsKeys.language: 'both'}),
      );
      await controller('cow').playLesson();
      final played = audio.voice.played;
      expect(played.first, 'assets/audio/hi/kido/look.m4a'); // देखो!
      final word = played.indexOf('assets/audio/en/cow.m4a');
      expect(played[word + 1], 'assets/audio/hi/cow.m4a');
      // The fact once, in Hindi; no English Kido lines.
      expect(played, contains('assets/audio/hi/cow_fact.m4a'));
      expect(played, isNot(contains('assets/audio/en/cow_fact.m4a')));
      expect(played.where((a) => a.contains('/en/kido/')), isEmpty);
    });

    test('"both" ABC: "A for Apple" in English, then सेब', () async {
      await setUpContainer(
        store: LocalStore.inMemory({SettingsKeys.language: 'both'}),
      );
      await controller('a_apple').playLesson();
      expect(audio.voice.played.sublist(1, 5), [
        'assets/audio/letters/a.m4a',
        'assets/audio/en/kido/for.m4a',
        'assets/audio/en/a_apple.m4a',
        'assets/audio/hi/a_apple.m4a',
      ]);
    });

    test('picture reacts while its sound plays', () async {
      await setUpContainer();
      audio.voice.holdPlayback = true;
      final lesson = controller('cow').playLesson();
      await playUntil('assets/audio/animals/cow.m4a');
      expect(stateOf('cow').reacting, isTrue);
      await playUntil('assets/audio/en/cow_fact.m4a');
      expect(stateOf('cow').reacting, isFalse);
      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await lesson;
    });

    test('tiles appear one by one as letters are spoken', () async {
      await setUpContainer();
      audio.voice.holdPlayback = true;
      final lesson = controller('cow').playLesson();
      await playUntil('assets/audio/letters/c.m4a');
      expect(stateOf('cow').highlighted, 0);
      expect(stateOf('cow').revealed, 1);
      await playUntil('assets/audio/letters/o.m4a');
      expect(stateOf('cow').highlighted, 1);
      expect(stateOf('cow').revealed, 2);
      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await lesson;
      expect(stateOf('cow').revealed, 3);
    });
  });

  test('Hindi letter: "अ से अनार" in Hindi, no English spelling', () async {
    await setUpContainer();
    await controller('hi_anar').playLesson();
    final played = audio.voice.played;
    expect(played.sublist(0, 5), [
      'assets/audio/hi/kido/look.m4a', // देखो! (Hindi even in English mode)
      'assets/audio/hi/letters/hi_anar.m4a', // अ
      'assets/audio/hi/kido/se.m4a', // से
      'assets/audio/hi/hi_anar.m4a', // अनार
      'assets/audio/hi/kido/say_with_me.m4a',
    ]);
    expect(played.where((a) => a.contains('/letters/') && !a.contains('/hi/')),
        isEmpty);
    expect(stateOf('hi_anar').revealed, 0);
    expect(stateOf('hi_anar').phase, LessonPhase.youDo);
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
    expect(audio.sfx.played, isEmpty); // no celebration
  });

  test('you do: tapping the picture celebrates and Kido praises', () async {
    await setUpContainer();
    await controller('cow').playLesson();
    audio.voice.played.clear();

    await controller('cow').tapPicture();
    expect(audio.sfxNames, ['cheer']);
    expect(stateOf('cow').celebrations, 1);
    expect(stateOf('cow').phase, LessonPhase.done);
    expect(audio.voice.played.single, startsWith('$kido/praise_'));
  });

  test(
    'we do (first visit): spell together, then "Where is the cow?"',
    () async {
      await setUpContainer();
      await controller('cow').playLesson(fullGuidance: true);
      expect(audio.voice.played.last, '$kido/spell_together.m4a');
      expect(stateOf('cow').phase, LessonPhase.weDo);
      expect(stateOf('cow').weDoTarget, 0);

      await controller('cow').tapLetter(0);
      expect(stateOf('cow').weDoTarget, 1);

      // A different letter is just said; the target stays. No "wrong".
      await controller('cow').tapLetter(2);
      expect(stateOf('cow').weDoTarget, 1);
      expect(audio.voice.played.last, 'assets/audio/letters/w.m4a');

      await controller('cow').tapLetter(1);
      audio.voice.played.clear();
      await controller('cow').tapLetter(2);

      expect(audio.voice.played.first, 'assets/audio/letters/w.m4a');
      expect(audio.voice.played, contains('assets/audio/en/cow.m4a'));
      expect(
        audio.voice.played.any((a) => a.contains('/kido/praise_')),
        isTrue,
      );
      expect(audio.voice.played.sublist(audio.voice.played.length - 3), [
        '$kido/where_is_the.m4a',
        'assets/audio/en/cow.m4a',
        '$kido/can_you_tap_it.m4a',
      ]);
      expect(stateOf('cow').phase, LessonPhase.youDo);
    },
  );

  testWidgets('idle hints escalate gently and any tap resets them', (
    tester,
  ) async {
    await setUpContainer();
    final lesson = controller('cow').playLesson();
    await tester.pump(AppDurations.echoPause);
    await lesson;
    expect(stateOf('cow').phase, LessonPhase.youDo);
    audio.voice.played.clear();

    await tester.pump(const Duration(seconds: 5));
    expect(stateOf('cow').hint, HintLevel.look);
    await tester.pump(const Duration(seconds: 5));
    expect(stateOf('cow').hint, HintLevel.point);
    expect(audio.voice.played, [
      '$kido/hint_tap.m4a', // "Here it is! Tap the" + cow
      'assets/audio/en/cow.m4a',
    ]);
    await tester.pump(const Duration(seconds: 5));
    expect(stateOf('cow').hint, HintLevel.glow);

    controller('cow').userTapped();
    expect(stateOf('cow').hint, HintLevel.none);
    await tester.pump(const Duration(seconds: 4));
    expect(stateOf('cow').hint, HintLevel.none);

    // Finishing the card stops the hints.
    await controller('cow').tapPicture();
    await tester.pump(const Duration(seconds: 30));
    expect(stateOf('cow').hint, HintLevel.none);
  });

  testWidgets('with sound off the lesson still runs silently', (tester) async {
    await setUpContainer(
      store: LocalStore.inMemory({SettingsKeys.sound: false}),
    );
    final lesson = controller('cow').playLesson();
    await tester.pump(const Duration(seconds: 30));
    await lesson;
    expect(audio.voice.played, isEmpty);
    expect(stateOf('cow').revealed, 3);
    expect(stateOf('cow').phase, LessonPhase.youDo);

    final tap = controller('cow').tapPicture();
    await tester.pump(const Duration(seconds: 2));
    await tap;
    expect(stateOf('cow').celebrations, 1);
    await tester.pump(const Duration(seconds: 30));
  });

  test('leaving the screen stops the voice', () async {
    await setUpContainer();
    final sub = container.listen(learnCardControllerProvider('hen'), (_, _) {});
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
