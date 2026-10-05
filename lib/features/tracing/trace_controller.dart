import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/learning_item.dart';
import '../../content/spelling.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../../core/theme/app_tokens.dart';
import '../kido/kido_voice.dart';
import 'trace_logic.dart';

@immutable
class TraceState {
  const TraceState({
    this.glyphs = const [],
    this.strokes = const [],
    this.at = const TracePosition(),
    this.demo = 0,
    this.strokesDone = 0,
    this.celebrations = 0,
  });

  /// The glyphs being written ("A", or "2", "1").
  final List<String> glyphs;

  /// Each glyph's strokes, resampled.
  final List<List<Stroke>> strokes;
  final TracePosition at;

  /// Bumps each time Kido shows how to write the current stroke.
  final int demo;

  /// Bumps on every finished stroke (pop + sparkle).
  final int strokesDone;

  /// Bumps when the whole word is written.
  final int celebrations;

  bool get ready => strokes.isNotEmpty;
  bool get finished => ready && at.glyph >= strokes.length;

  /// The stroke the child should write now, if any.
  Stroke? get currentStroke =>
      finished || !ready ? null : strokes[at.glyph][at.stroke];

  TraceState copyWith({
    List<String>? glyphs,
    List<List<Stroke>>? strokes,
    TracePosition? at,
    int? demo,
    int? strokesDone,
    int? celebrations,
  }) => TraceState(
    glyphs: glyphs ?? this.glyphs,
    strokes: strokes ?? this.strokes,
    at: at ?? this.at,
    demo: demo ?? this.demo,
    strokesDone: strokesDone ?? this.strokesDone,
    celebrations: celebrations ?? this.celebrations,
  );
}

/// Finger tracing for one item: "Let's write A!", a demo of each stroke,
/// gentle idle hints, and a cheer at the end. Never says "wrong".
class TraceController extends Notifier<TraceState> {
  TraceController(this.itemId);

  final String itemId;
  LearningItem? _item;
  Timer? _idle;
  int _hints = 0;

  /// Idle hints never repeat more than this many times in a row.
  static const maxHints = 2;

  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  TraceState build() {
    final audio = _audio;
    ref.onDispose(() {
      _idle?.cancel();
      unawaited(audio.stopVoice(owner: this));
    });
    return const TraceState();
  }

  /// Starts writing [item] with [guides].
  Future<void> start(LearningItem item, TraceGuides guides) async {
    final glyphs = guides.glyphsFor(item);
    if (glyphs == null) return;
    _item = item;
    _hints = 0;
    state = TraceState(
      glyphs: glyphs,
      strokes: [for (final g in glyphs) guides.strokesOf(g)!],
      demo: state.demo + 1,
      celebrations: state.celebrations,
    );
    await _say(KidoEvent.traceIt);
    _armIdle();
  }

  /// The finger is at [point] (unit box) over glyph [glyph].
  void move(int glyph, Offset point) {
    if (!state.ready || state.finished) return;
    _hints = 0;
    _armIdle();
    final (at, step) = TraceRules.move(state.strokes, state.at, glyph, point);
    if (step == TraceStep.none) return;
    state = state.copyWith(at: at);
    switch (step) {
      case TraceStep.none || TraceStep.progress:
        break;
      case TraceStep.strokeDone || TraceStep.glyphDone:
        _audio.playSfx(Sfx.pop);
        ref.read(hapticsProvider).tap();
        state = state.copyWith(strokesDone: state.strokesDone + 1);
      case TraceStep.allDone:
        _idle?.cancel();
        _audio.playSfx(Sfx.cheer);
        ref.read(hapticsProvider).tap();
        state = state.copyWith(
          strokesDone: state.strokesDone + 1,
          celebrations: state.celebrations + 1,
        );
        unawaited(_cheer());
    }
  }

  /// Write it again.
  void again() {
    if (!state.ready) return;
    _hints = 0;
    state = state.copyWith(at: const TracePosition(), demo: state.demo + 1);
    _armIdle();
  }

  Future<void> _cheer() async {
    await _say(KidoEvent.praise);
    if (!ref.mounted) return;
    await _say(KidoEvent.traceDone);
  }

  /// Idle: show the stroke again; twice at most until the child moves.
  void _armIdle() {
    _idle?.cancel();
    _idle = Timer(AppDurations.traceIdle, () {
      if (!ref.mounted || state.finished || _hints >= maxHints) return;
      _hints++;
      state = state.copyWith(demo: state.demo + 1);
      unawaited(_say(KidoEvent.traceHint));
      _armIdle();
    });
  }

  Future<void> _say(String event) async {
    final item = _item;
    if (!ref.mounted || item == null) return;
    await ref
        .read(kidoVoiceProvider)
        .say(event, item: item, itemAudio: _glyphAudio(item), owner: this);
  }

  /// Letters are named by their letter clip ("A"), numbers by their name.
  static String? _glyphAudio(LearningItem item) =>
      item.letter != null && item.number == null
      ? letterAudioAsset(item.letter!)
      : null;
}

final traceControllerProvider = NotifierProvider.autoDispose
    .family<TraceController, TraceState, String>(TraceController.new);
