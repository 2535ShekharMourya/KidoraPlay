import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/games/quiz_controller.dart';
import 'package:kidoraplay/features/games/quiz_models.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

const kido = 'assets/audio/en/kido';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  group('buildQuiz', () {
    for (final kind in GameKind.values) {
      for (final level in Level.values) {
        test('${kind.name} at ${level.name}', () {
          final rounds = buildQuiz(kind, catalog, level, Random(3));
          expect(rounds, hasLength(roundsFor(level)));
          expect(
            rounds.map((r) => r.answer.id).toSet(),
            hasLength(roundsFor(level)),
            reason: 'answers do not repeat in a game',
          );
          for (final r in rounds) {
            expect(r.choices, hasLength(choicesFor(level)));
            expect(r.choices.toSet(), hasLength(r.choices.length));
            expect(r.choices, contains(r.answer));
          }
        });
      }
    }

    test('who-says only uses items with a sound', () {
      final rounds = buildQuiz(GameKind.whoSays, catalog, Level.ukg, Random(1));
      for (final r in rounds) {
        for (final c in r.choices) {
          expect(c.item!.sound, isNotNull);
        }
      }
    });

    test('count-it: Nursery counts to 5; the picture count is the answer', () {
      for (var seed = 0; seed < 20; seed++) {
        final rounds = buildQuiz(
          GameKind.countIt,
          catalog,
          Level.nursery,
          Random(seed),
        );
        for (final r in rounds) {
          expect(r.count, inInclusiveRange(1, 5));
          expect(r.answer.text, '${r.count}');
          expect(r.subject, isNotNull);
          expect(r.answer.clip, isNotNull);
        }
      }
    });

    test('letters: choices are letters with their sounds', () {
      final r = buildQuiz(
        GameKind.letters,
        catalog,
        Level.lkg,
        Random(2),
      ).first;
      for (final c in r.choices) {
        expect(c.text, matches(RegExp(r'^[A-Z]$')));
        expect(c.clip, 'assets/audio/letters/${c.text!.toLowerCase()}.m4a');
      }
    });
  });

  group('QuizController', () {
    late FakeAudio audio;
    late ProviderContainer c;

    Future<QuizController> startGame(GameKind kind, {Level? level}) async {
      audio = FakeAudio();
      c = ProviderContainer(
        overrides: [
          ...testOverrides(
            audio: audio,
            catalog: catalog,
            store: LocalStore.inMemory({
              SettingsKeys.language: 'en',
              if (level != null) SettingsKeys.level: level.name,
            }),
          ),
          quizRandomProvider.overrideWithValue(Random(7)),
        ],
      );
      addTearDown(c.dispose);
      await c.read(contentCatalogProvider.future);
      c.listen(quizControllerProvider(kind), (_, _) {});
      final game = c.read(quizControllerProvider(kind).notifier);
      await game.start();
      return game;
    }

    QuizState stateOf(GameKind kind) => c.read(quizControllerProvider(kind));

    test('find-it: "Let\'s play!" then "Where is the …?"', () async {
      await startGame(GameKind.findIt);
      final answer = stateOf(GameKind.findIt).round!.answer;
      expect(audio.voice.played, [
        '$kido/lets_play.m4a',
        '$kido/where_is_the.m4a',
        answer.item!.voiceEn,
        '$kido/can_you_tap_it.m4a',
      ]);
      expect(stateOf(GameKind.findIt).phase, QuizPhase.asking);
    });

    test('who-says plays the real animal sound', () async {
      await startGame(GameKind.whoSays);
      final answer = stateOf(GameKind.whoSays).round!.answer;
      expect(audio.voice.played.last, answer.item!.sound);
    });

    test(
      'another picture is just named; two misses make the answer glow',
      () async {
        final game = await startGame(GameKind.findIt);
        final round = stateOf(GameKind.findIt).round!;
        final other = round.choices.firstWhere((x) => x != round.answer);
        audio.voice.played.clear();

        await game.tap(other);
        expect(audio.voice.played, [
          '$kido/thats.m4a', // "That's" + dog
          other.item!.voiceEn,
        ]);
        expect(stateOf(GameKind.findIt).answerGlows, isFalse);
        expect(stateOf(GameKind.findIt).solved, 0);

        await game.tap(other);
        expect(stateOf(GameKind.findIt).answerGlows, isTrue);
        expect(stateOf(GameKind.findIt).phase, QuizPhase.asking);
        expect(audio.sfx.played, isEmpty); // no buzzers, ever
      },
    );

    test('the right answer cheers and moves to the next round', () async {
      final game = await startGame(GameKind.letters);
      final round = stateOf(GameKind.letters).round!;
      audio.voice.played.clear();

      await game.tap(round.answer);
      expect(audio.sfxNames, ['cheer']);
      expect(audio.voice.played.first, round.answer.clip);
      expect(stateOf(GameKind.letters).solved, 1);
      expect(stateOf(GameKind.letters).index, 1);
      expect(stateOf(GameKind.letters).phase, QuizPhase.asking);
    });

    test('five right answers finish the game with a celebration', () async {
      final game = await startGame(GameKind.countIt, level: Level.nursery);
      for (var i = 0; i < roundsPerGame; i++) {
        await game.tap(stateOf(GameKind.countIt).round!.answer);
      }
      final s = stateOf(GameKind.countIt);
      expect(s.phase, QuizPhase.finished);
      expect(s.solved, roundsPerGame);
      expect(s.games, 1);
      expect(audio.voice.played.last, startsWith('$kido/game_done_'));

      // Play again starts fresh.
      await game.start();
      expect(stateOf(GameKind.countIt).solved, 0);
      expect(stateOf(GameKind.countIt).phase, QuizPhase.asking);
    });

    test('taps after answering are ignored until the next question', () async {
      final game = await startGame(GameKind.findIt);
      final round = stateOf(GameKind.findIt).round!;
      audio.voice.holdPlayback = true;
      final first = game.tap(round.answer);
      await pumpEventQueue();
      await game.tap(round.answer); // mashing
      expect(stateOf(GameKind.findIt).solved, 1);
      audio.voice.holdPlayback = false;
      audio.voice.finishCurrent();
      await first;
    });
  });

  test('the games use content from every Phase 1 section', () {
    expect(GameKind.values.map((k) => k.theme).toSet(), {
      SectionId.animals,
      SectionId.birds,
      SectionId.numbers,
      SectionId.abc,
    });
  });
}
