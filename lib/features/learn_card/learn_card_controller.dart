import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_tokens.dart';

@immutable
class LearnCardState {
  const LearnCardState({
    this.highlighted,
    this.revealed = 0,
    this.reacting = false,
    this.playing = false,
    this.celebrations = 0,
  });

  /// Spelling tile currently lit up, if any.
  final int? highlighted;

  /// How many spelling tiles are visible (they appear one by one).
  final int revealed;

  /// The picture is reacting to its sound (animals, birds).
  final bool reacting;

  /// The lesson is running.
  final bool playing;

  /// Increments each time a lesson finishes; the screen celebrates.
  final int celebrations;

  LearnCardState copyWith({
    int? highlighted,
    bool clearHighlight = false,
    int? revealed,
    bool? reacting,
    bool? playing,
    int? celebrations,
  }) =>
      LearnCardState(
        highlighted: clearHighlight ? null : highlighted ?? this.highlighted,
        revealed: revealed ?? this.revealed,
        reacting: reacting ?? this.reacting,
        playing: playing ?? this.playing,
        celebrations: celebrations ?? this.celebrations,
      );
}

/// Runs the learn-card lesson for one item:
///
/// 1. Real sound with the picture reacting (animals, birds).
/// 2. Say the word ("Apple!").
/// 3. Spell it: tiles appear one by one and light up as each letter is
///    spoken (A … P … P … L … E).
/// 4. Say the word again, then celebrate.
///
/// With sound off or a missing clip, the same steps run silently on a timer
/// so the child still sees the spelling.
class LearnCardController extends Notifier<LearnCardState> {
  LearnCardController(this.itemId);

  final String itemId;
  int _run = 0;

  LearningItem? get _item =>
      ref.read(contentCatalogProvider).value?.itemById(itemId);

  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  LearnCardState build() {
    final audio = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _run++;
      unawaited(audio.stopVoice());
    });
    return const LearnCardState();
  }

  bool _alive(int run) => ref.mounted && run == _run;

  /// Starts (or restarts) the full lesson.
  Future<void> playLesson() async {
    final item = _item;
    if (item == null) return;
    final run = ++_run;
    final tiles = item.spelling;
    final languages = ref.read(settingsProvider).language.languages;
    final words = [for (final l in languages) item.voice(l)];

    state = state.copyWith(playing: true, clearHighlight: true);

    if (item.sound case final sound?) {
      state = state.copyWith(reacting: true);
      await _speak([sound], run);
      if (!_alive(run)) return;
      state = state.copyWith(reacting: false);
    }

    await _speak(words, run);
    if (!_alive(run)) return;

    final voiced = [
      for (final (i, t) in tiles.indexed)
        if (t.isVoiced) i,
    ];
    await _speak(
      [for (final i in voiced) tiles[i].audioAsset!],
      run,
      onSegment: (k) {
        if (!_alive(run)) return;
        state = state.copyWith(
          highlighted: voiced[k],
          revealed: math.max(state.revealed, voiced[k] + 1),
        );
      },
    );
    if (!_alive(run)) return;
    state = state.copyWith(clearHighlight: true, revealed: tiles.length);

    await _speak(words, run);
    if (!_alive(run)) return;

    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(
      playing: false,
      celebrations: state.celebrations + 1,
    );
  }

  /// Child tapped a letter tile: stop the lesson and say that letter.
  Future<void> tapLetter(int index) async {
    final item = _item;
    if (item == null) return;
    final tile = item.spelling[index];
    final audio = tile.audioAsset;
    if (audio == null) return;

    final run = ++_run;
    state = state.copyWith(
      highlighted: index,
      revealed: item.spelling.length,
      reacting: false,
      playing: false,
    );
    await _speak([audio], run);
    if (_alive(run)) state = state.copyWith(clearHighlight: true);
  }

  /// Plays [assets]; if nothing could be heard (muted or missing audio),
  /// steps through the segments silently so the visuals keep their rhythm.
  Future<void> _speak(
    List<String> assets,
    int run, {
    void Function(int index)? onSegment,
  }) async {
    final ok = await _audio.playVoiceSequence(
      assets,
      onSegment: onSegment,
      debounce: false,
    );
    if (ok || !_alive(run)) return;
    for (var i = 0; i < assets.length; i++) {
      if (!_alive(run)) return;
      onSegment?.call(i);
      await Future<void>.delayed(AppDurations.silentSegment);
    }
  }
}

final learnCardControllerProvider = NotifierProvider.autoDispose
    .family<LearnCardController, LearnCardState, String>(
  LearnCardController.new,
);
