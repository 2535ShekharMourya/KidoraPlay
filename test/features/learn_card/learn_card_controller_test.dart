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
import 'package:kidoraplay/features/progress/progress_controller.dart';

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
      // A child who already knows to tap pictures, unless a test says not.
      overrides: testOverrides(
        audio: audio,
        catalog: catalog,
        store:
            store ??
            LocalStore.inMemory({
              SettingsKeys.language: 'en',
              'kido.discovered': true,
            }),
      ),
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
    // Real time passes too: spelled letters have short pauses between.
    for (var i = 0; i < 150 && audio.voice.played.lastOrNull != clip; i++) {
      audio.voice.finishCurrent();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(audio.voice.played.last, clip);
  }

  /// Taps the picture and returns what it played.
  Future<List<String>> tap(String id) async {
    audio.voice.played.clear();
    await controller(id).tapPicture();
    return [...audio.voice.played];
  }

  group('the card opens short', () {
    test('just the name, then it is the child\'s turn', () async {
      await setUpContainer();
      await controller('cow').playLesson();
      // "This is a cow!"
      expect(audio.voice.played, ['assets/audio/en/cow_intro.m4a']);
      final s = stateOf('cow');
      expect(s.phase, LessonPhase.youDo);
      expect(s.busy, isFalse);
      expect(s.stars, 0);
      expect(s.starGoal, 3);
      // The word is on screen from the start, ready to tap.
      expect(s.revealed, 3);
    });

    test('ABC: "A for Apple!" in one breath', () async {
      await setUpContainer();
      await controller('a_apple').playLesson();
      expect(audio.voice.played, ['assets/audio/en/a_apple_intro.m4a']);
    });

    test('"both" ABC: "A for Apple!" in English, then सेब', () async {
      await setUpContainer(
        store: LocalStore.inMemory({
          SettingsKeys.language: 'both',
          'kido.discovered': true,
        }),
      );
      await controller('a_apple').playLesson();
      expect(audio.voice.played, [
        'assets/audio/en/a_apple_intro.m4a',
        'assets/audio/hi/a_apple.m4a',
      ]);
    });

    test('Hindi letter: "अ से अनार!"', () async {
      await setUpContainer();
      await controller('hi_anar').playLesson();
      expect(audio.voice.played, ['assets/audio/hi/hi_anar_intro.m4a']);
      expect(stateOf('hi_anar').revealed, greaterThan(0));
    });

    test('"Tap the picture!" until the child has tapped once', () async {
      await setUpContainer(
        store: LocalStore.inMemory({SettingsKeys.language: 'en'}),
      );
      await controller('cow').playLesson();
      expect(audio.voice.played, [
        'assets/audio/en/cow_intro.m4a',
        '$kido/tap_to_play.m4a',
      ]);
      await controller('cow').tapPicture();
      audio.voice.played.clear();
      await controller('dog').playLesson();
      expect(audio.voice.played, ['assets/audio/en/dog_intro.m4a']);
    });
  });

  group('each tap discovers something and earns a star', () {
    test('animal: sound → fact → spelling, then done', () async {
      await setUpContainer();
      await controller('cow').playLesson();

      expect(await tap('cow'), [
        'assets/audio/animals/cow.m4a',
        'assets/audio/en/cow.m4a',
      ]);
      expect(stateOf('cow').stars, 1);
      expect(audio.sfxNames, ['sparkle']);

      expect(await tap('cow'), ['assets/audio/en/cow_fact.m4a']);
      expect(stateOf('cow').stars, 2);
      expect(stateOf('cow').phase, LessonPhase.youDo);

      final third = await tap('cow');
      expect(third.sublist(0, 6), [
        '$kido/lets_spell.m4a', // "Let's learn to spell" + Cow
        'assets/audio/en/cow.m4a',
        'assets/audio/letters/c.m4a',
        'assets/audio/letters/o.m4a',
        'assets/audio/letters/w.m4a',
        'assets/audio/en/cow.m4a',
      ]);
      final s = stateOf('cow');
      expect(s.stars, 3);
      expect(s.phase, LessonPhase.done);
      expect(s.celebrations, 1);
      expect(s.stickers, 1);
      // Praise, then on to the next one.
      expect(third[6], startsWith('$kido/praise_'));
      expect(third.last, startsWith('$kido/next_one_'));
      expect(container.read(progressProvider).learned, contains('cow'));
    });

    test('after the stars, taps keep discovering (no more stars)', () async {
      await setUpContainer();
      await controller('cow').playLesson();
      for (var i = 0; i < 3; i++) {
        await tap('cow');
      }
      final fourth = await tap('cow');
      expect(fourth.first, '$kido/say_with_me.m4a');
      expect(stateOf('cow').stars, 3);
      expect(stateOf('cow').celebrations, 1);
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
        // Stars light up as they are counted, then "How many stars? Three!"
        expect(await tap('three'), [
          '$kido/count_stars.m4a',
          'assets/audio/en/one.m4a',
          'assets/audio/en/two.m4a',
          'assets/audio/en/three.m4a',
          '$kido/how_many_stars.m4a',
          'assets/audio/en/three.m4a',
        ]);
        expect(counts.toSet().containsAll([1, 2, 3]), isTrue);
        expect(stateOf('three').counted, 0);
      },
    );

    test('big numbers: no counting; hyphen shown but not spoken', () async {
      await setUpContainer();
      await controller('twenty_one').playLesson();
      expect(stateOf('twenty_one').starGoal, 2); // spell, say
      final letters = (await tap('twenty_one'))
          .where((a) => a.contains('/letters/'))
          .map((a) => a.split('/').last.split('.').first)
          .join();
      expect(letters, 'twentyone');
      expect(stateOf('twenty_one').revealed, 'TWENTY-ONE'.length);
    });

    test('"both": the fact once, in Hindi; no English Kido lines', () async {
      await setUpContainer(
        store: LocalStore.inMemory({
          SettingsKeys.language: 'both',
          'kido.discovered': true,
        }),
      );
      await controller('cow').playLesson();
      // "This is a cow!" + "यह गाय है!"
      expect(audio.voice.played, [
        'assets/audio/en/cow_intro.m4a',
        'assets/audio/hi/cow_intro.m4a',
      ]);
      await tap('cow');
      expect(await tap('cow'), ['assets/audio/hi/cow_fact.m4a']);
    });

    test('"both": a word that sounds the same is said once', () async {
      await setUpContainer(
        store: LocalStore.inMemory({
          SettingsKeys.language: 'both',
          'kido.discovered': true,
        }),
      );
      await controller('truck').playLesson();
      // "यह ट्रक है!" only, never "Truck… ट्रक".
      expect(audio.voice.played, ['assets/audio/hi/truck_intro.m4a']);
    });

    test('Hindi: chat, then the letter and word, then say it', () async {
      await setUpContainer();
      await controller('hi_anar').playLesson();
      expect(await tap('hi_anar'), ['assets/audio/hi/hi_anar_fact.m4a']);
      expect(await tap('hi_anar'), [
        'assets/audio/hi/letters/hi_anar.m4a',
        'assets/audio/hi/hi_anar.m4a',
      ]);
      expect(
        audio.voice.played.where((a) => a.startsWith('assets/audio/letters/')),
        isEmpty,
      );
    });

    test('the picture reacts while its sound plays', () async {
      await setUpContainer();
      await controller('cow').playLesson();
      audio.voice.holdPlayback = true;
      final t = controller('cow').tapPicture();
      await playUntil('assets/audio/animals/cow.m4a');
      expect(stateOf('cow').reacting, isTrue);
      expect(stateOf('cow').discovery, Discovery.sound);
      await playUntil('assets/audio/en/cow.m4a');
      expect(stateOf('cow').reacting, isFalse);
      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await t;
      expect(stateOf('cow').busy, isFalse);
    });

    test('letters light up one by one as they are spoken', () async {
      await setUpContainer();
      await controller('cow').playLesson();
      await tap('cow');
      await tap('cow');
      audio.voice.holdPlayback = true;
      final t = controller('cow').tapPicture();
      await playUntil('assets/audio/letters/c.m4a');
      expect(stateOf('cow').highlighted, 0);
      await playUntil('assets/audio/letters/o.m4a');
      expect(stateOf('cow').highlighted, 1);
      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await t;
      expect(stateOf('cow').highlighted, isNull);
    });
  });

  group('taps never break anything', () {
    test('mashing during a discovery just pops: no restart, no cut', () async {
      await setUpContainer();
      await controller('cow').playLesson();
      audio.voice.holdPlayback = true;
      final first = controller('cow').tapPicture();
      await pumpEventQueue();
      final stops = audio.voice.stops;

      await controller('cow').tapPicture();
      await controller('cow').tapPicture();
      expect(audio.voice.stops, stops); // nothing was cut off
      expect(stateOf('cow').stars, 1); // no extra stars
      expect(audio.sfxNames.where((s) => s == 'pop'), hasLength(2));

      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await first;
    });

    test('tapping during the name skips straight to discovering', () async {
      await setUpContainer();
      audio.voice.holdPlayback = true;
      final lesson = controller('cow').playLesson();
      await pumpEventQueue();
      expect(stateOf('cow').phase, LessonPhase.iDo);

      // The tap takes over (the name is stopped, not finished).
      audio.voice.holdPlayback = false;
      await controller('cow').tapPicture();
      await lesson;
      expect(stateOf('cow').stars, 1);
      expect(audio.voice.played, contains('assets/audio/animals/cow.m4a'));
      expect(stateOf('cow').busy, isFalse);
    });

    test('tapping a letter says that letter (and frees the picture)', () async {
      await setUpContainer();
      await controller('cow').playLesson();
      audio.voice.holdPlayback = true;
      final discovering = controller('cow').tapPicture();
      await pumpEventQueue();

      final letter = controller('cow').tapLetter(2);
      await pumpEventQueue();
      expect(stateOf('cow').highlighted, 2);
      expect(stateOf('cow').busy, isFalse);
      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await letter;
      await discovering;

      expect(audio.voice.played.last, 'assets/audio/letters/w.m4a');
      expect(stateOf('cow').highlighted, isNull);
    });
  });

  testWidgets('a quiet child gets gentle hints; any tap resets them', (
    tester,
  ) async {
    await setUpContainer();
    await controller('cow').playLesson();
    audio.voice.played.clear();

    await tester.pump(AppDurations.discoverLook);
    expect(stateOf('cow').hint, HintLevel.look);
    expect(audio.voice.played, isEmpty); // looking is silent
    await tester.pump(AppDurations.discoverPoint - AppDurations.discoverLook);
    expect(stateOf('cow').hint, HintLevel.point);
    expect(audio.voice.played, [
      '$kido/hint_tap.m4a', // "Here it is! Tap the" + cow
      'assets/audio/en/cow.m4a',
    ]);
    await tester.pump(AppDurations.discoverGlow - AppDurations.discoverPoint);
    expect(stateOf('cow').hint, HintLevel.glow);

    // Only one spoken hint per card: then Kido waits quietly.
    audio.voice.played.clear();
    await tester.pump(const Duration(seconds: 60));
    expect(audio.voice.played, isEmpty);

    controller('cow').userTapped();
    expect(stateOf('cow').hint, HintLevel.none);
    await tester.pump(const Duration(seconds: 60));
  });

  testWidgets('with sound off everything still runs silently', (tester) async {
    await setUpContainer(
      store: LocalStore.inMemory({
        SettingsKeys.sound: false,
        'kido.discovered': true,
      }),
    );
    final lesson = controller('cow').playLesson();
    await tester.pump(const Duration(seconds: 5));
    await lesson;
    expect(stateOf('cow').phase, LessonPhase.youDo);
    for (var i = 0; i < 3; i++) {
      final t = controller('cow').tapPicture();
      await tester.pump(const Duration(seconds: 5));
      await t;
    }
    expect(audio.voice.played, isEmpty);
    expect(stateOf('cow').celebrations, 1);
    await tester.pump(const Duration(seconds: 60));
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
