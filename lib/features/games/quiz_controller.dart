import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/learning_item.dart';
import '../../content/models/level.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_tokens.dart';
import '../kido/hint_timer.dart';
import '../kido/kido_voice.dart';
import 'quiz_models.dart';

enum QuizPhase { idle, asking, correct, finished }

@immutable
class QuizState {
  const QuizState({
    this.rounds = const [],
    this.index = 0,
    this.phase = QuizPhase.idle,
    this.solved = 0,
    this.wrongTaps = 0,
    this.lastWrong,
    this.wrongSeq = 0,
    this.hint = HintLevel.none,
    this.games = 0,
  });

  final List<QuizRound> rounds;
  final int index;
  final QuizPhase phase;

  /// Rounds answered (fills the progress stars).
  final int solved;

  /// Different-choice taps this round (2 → the answer glows).
  final int wrongTaps;

  /// Last other choice tapped, and a counter so the same one re-wiggles.
  final String? lastWrong;
  final int wrongSeq;
  final HintLevel hint;

  /// Increments each time a game is finished (celebration).
  final int games;

  QuizRound? get round => index < rounds.length ? rounds[index] : null;

  /// The answer calls attention to itself after two misses or when idle.
  bool get answerGlows => wrongTaps >= 2 || hint == HintLevel.glow;

  QuizState copyWith({
    List<QuizRound>? rounds,
    int? index,
    QuizPhase? phase,
    int? solved,
    int? wrongTaps,
    String? lastWrong,
    int? wrongSeq,
    HintLevel? hint,
    int? games,
  }) => QuizState(
    rounds: rounds ?? this.rounds,
    index: index ?? this.index,
    phase: phase ?? this.phase,
    solved: solved ?? this.solved,
    wrongTaps: wrongTaps ?? this.wrongTaps,
    lastWrong: lastWrong ?? this.lastWrong,
    wrongSeq: wrongSeq ?? this.wrongSeq,
    hint: hint ?? this.hint,
    games: games ?? this.games,
  );
}

/// Random source for games; tests override it for repeatable rounds.
final quizRandomProvider = Provider<math.Random>((ref) => math.Random());

/// Runs one game: Kido asks, the child taps, Kido cheers. A different
/// choice is simply named ("That's a dog!"), never called wrong; after
/// two of those, or when the child is idle, the answer glows.
class QuizController extends Notifier<QuizState> {
  QuizController(this.kind);

  final GameKind kind;
  int _run = 0;
  bool _disposed = false;
  late final HintTimer _hints = HintTimer(onLevel: _onHint);

  AudioService get _audio => ref.read(audioServiceProvider);
  ContentLanguage get _lang =>
      ref.read(settingsProvider).language.languages.first;

  @override
  QuizState build() {
    final audio = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _disposed = true;
      _run++;
      _hints.stop();
      unawaited(audio.stopVoice(owner: this));
    });
    return const QuizState();
  }

  bool _alive(int run) => !_disposed && ref.mounted && run == _run;

  /// Starts (or restarts) the game with fresh rounds.
  Future<void> start() async {
    final catalog = ref.read(contentCatalogProvider).value;
    if (catalog == null) return;
    final run = ++_run;
    _hints.stop();
    final rounds = buildQuiz(
      kind,
      catalog,
      ref.read(settingsProvider).level,
      ref.read(quizRandomProvider),
    );
    state = QuizState(rounds: rounds, games: state.games);
    await _say(KidoEvent.letsPlay, run);
    if (!_alive(run)) return;
    await _ask(run);
  }

  Future<void> _ask(int run) async {
    state = state.copyWith(
      phase: QuizPhase.asking,
      wrongTaps: 0,
      hint: HintLevel.none,
    );
    await _prompt(run);
    if (_alive(run) && state.phase == QuizPhase.asking) _hints.start();
  }

  /// Asks the current question (also from the "hear again" button).
  Future<void> replayPrompt() async {
    if (state.phase != QuizPhase.asking) return;
    _hints.reset();
    await _prompt(_run);
  }

  Future<void> _prompt(int run) async {
    final round = state.round;
    if (round == null) return;
    switch (kind) {
      case GameKind.findIt:
        await _say(KidoEvent.findIt, run, item: round.answer.item);
      case GameKind.whoSays:
        await _say(KidoEvent.whoSays, run);
        if (!_alive(run)) return;
        if (round.answer.item?.sound case final sound?) {
          await _speak([sound], run);
        }
      case GameKind.countIt:
        await _say(KidoEvent.howMany, run);
      case GameKind.letters:
        await _say(KidoEvent.findLetter, run, letterAudio: round.answer.clip);
    }
  }

  /// Child tapped a choice.
  Future<void> tap(QuizChoice choice) async {
    final round = state.round;
    if (round == null || state.phase != QuizPhase.asking) return;
    _hints.reset();

    if (choice != round.answer) {
      final run = _run;
      state = state.copyWith(
        wrongTaps: state.wrongTaps + 1,
        lastWrong: choice.id,
        wrongSeq: state.wrongSeq + 1,
      );
      // Name what they tapped; no "wrong".
      if (choice.item != null && choice.text == null) {
        await _say(KidoEvent.thatsA, run, item: choice.item);
      } else {
        await _speak([?choice.clip], run);
      }
      return;
    }

    final run = ++_run;
    _hints.stop();
    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(phase: QuizPhase.correct, solved: state.solved + 1);
    await _speak([?_nameClip(choice)], run);
    if (!_alive(run)) return;
    await _say(KidoEvent.yay, run);
    if (!_alive(run)) return;
    await Future<void>.delayed(AppDurations.quizNext);
    if (!_alive(run)) return;

    if (state.index + 1 < state.rounds.length) {
      state = state.copyWith(index: state.index + 1);
      await _ask(run);
    } else {
      _audio.playSfx(Sfx.sparkle);
      state = state.copyWith(phase: QuizPhase.finished, games: state.games + 1);
      await _say(KidoEvent.gameDone, run);
    }
  }

  String? _nameClip(QuizChoice choice) =>
      choice.text != null ? choice.clip : choice.item?.voice(_lang);

  /// Any tap on the screen: hints restart.
  void userTapped() => _hints.reset();

  void _onHint(HintLevel level) {
    if (_disposed) return;
    state = state.copyWith(hint: level);
    if (level == HintLevel.point) unawaited(_prompt(_run));
  }

  Future<void> _speak(List<String> clips, int run) async {
    if (clips.isEmpty || !_alive(run)) return;
    final ok = await _audio.playVoiceSequence(
      clips,
      debounce: false,
      owner: this,
    );
    if (!ok && _alive(run)) {
      await Future<void>.delayed(AppDurations.silentSegment);
    }
  }

  Future<void> _say(
    String event,
    int run, {
    LearningItem? item,
    String? letterAudio,
  }) async {
    if (!_alive(run)) return;
    final ok = await ref
        .read(kidoVoiceProvider)
        .say(event, item: item, letterAudio: letterAudio, owner: this);
    if (!ok && _alive(run)) {
      await Future<void>.delayed(AppDurations.silentSegment);
    }
  }
}

final quizControllerProvider = NotifierProvider.autoDispose
    .family<QuizController, QuizState, GameKind>(QuizController.new);
