import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/json_reader.dart';
import '../../content/models/level.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_tokens.dart';

/// One note of a line's tune: a pitch ("g5") and how many beats it lasts.
typedef TuneNote = ({String pitch, int beats});

@immutable
class RhymeLine {
  const RhymeLine({
    required this.text,
    required this.voice,
    required this.tune,
  });

  factory RhymeLine.fromJson(Object? json, String where) {
    final r = JsonReader(json, where);
    return RhymeLine(
      text: r.string('text'),
      voice: r.string('voice'),
      tune: List.unmodifiable([
        for (final n in r.string('tune').split(' '))
          if (n.contains(':'))
            (
              pitch: n.split(':').first,
              beats: int.tryParse(n.split(':').last) ?? 1,
            ),
      ]),
    );
  }

  final String text;
  final String voice;
  final List<TuneNote> tune;
}

/// A rhyme (from `assets/content/rhymes.json`, `tool/make_rhymes.py`):
/// public-domain or original only.
@immutable
class Rhyme {
  const Rhyme({
    required this.id,
    required this.language,
    required this.levels,
    required this.titleEn,
    required this.titleHi,
    required this.image,
    required this.lines,
  });

  factory Rhyme.fromJson(Object? json) {
    final where =
        'rhymes.json "${JsonReader(json, 'rhymes.json').optString('id')}"';
    final r = JsonReader(json, where);
    return Rhyme(
      id: r.string('id'),
      language: parseEnum(ContentLanguage.values, r.string('language'), where),
      levels: List.unmodifiable(
        r.stringList('levels').map((l) => parseEnum(Level.values, l, where)),
      ),
      titleEn: r.string('title_en'),
      titleHi: r.string('title_hi'),
      image: r.string('image'),
      lines: List.unmodifiable([
        for (final (i, l) in r.list('lines').indexed)
          RhymeLine.fromJson(l, '$where line ${i + 1}'),
      ]),
    );
  }

  final String id;

  /// The language the rhyme is in (it is always sung in that language).
  final ContentLanguage language;
  final List<Level> levels;
  final String titleEn;
  final String titleHi;
  final String image;
  final List<RhymeLine> lines;

  String title(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => titleEn,
    ContentLanguage.hi => titleHi,
  };

  /// Every asset the rhyme needs (for validation).
  Iterable<String> get assets sync* {
    yield image;
    for (final l in lines) {
      yield l.voice;
      for (final n in l.tune) {
        yield noteAsset(n.pitch);
      }
    }
  }
}

String noteAsset(String pitch) => 'assets/audio/music/notes/$pitch.m4a';

Future<List<Rhyme>> loadRhymes(AssetBundle bundle) async {
  final raw = await bundle.loadString('assets/content/rhymes.json');
  return List.unmodifiable([
    for (final r in jsonDecode(raw) as List) Rhyme.fromJson(r),
  ]);
}

final rhymesProvider = FutureProvider<List<Rhyme>>(
  (ref) => loadRhymes(rootBundle),
);

@immutable
class RhymeState {
  const RhymeState({
    this.line,
    this.beat = 0,
    this.playing = false,
    this.finished = 0,
  });

  /// The line being played now (null between plays).
  final int? line;

  /// Increments on every note (the picture bounces to it).
  final int beat;
  final bool playing;

  /// Increments when the rhyme has been played to the end.
  final int finished;

  RhymeState copyWith({
    int? line,
    bool clearLine = false,
    int? beat,
    bool? playing,
    int? finished,
  }) => RhymeState(
    line: clearLine ? null : line ?? this.line,
    beat: beat ?? this.beat,
    playing: playing ?? this.playing,
    finished: finished ?? this.finished,
  );
}

/// Plays a rhyme line by line: the line's tune on the xylophone, then Kido
/// says the line in rhythm, with the line lit up.
class RhymeController extends Notifier<RhymeState> {
  RhymeController(this.rhymeId);

  final String rhymeId;
  int _run = 0;

  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  RhymeState build() {
    final audio = _audio;
    ref.onDispose(() {
      _run++;
      unawaited(audio.stopVoice(owner: this));
    });
    return const RhymeState();
  }

  bool _alive(int run) => ref.mounted && run == _run;

  /// Plays [rhyme] from the start (again if it is playing).
  Future<void> play(Rhyme rhyme) async {
    final run = ++_run;
    unawaited(
      _audio.preloadNotes({
        for (final l in rhyme.lines)
          for (final n in l.tune) noteAsset(n.pitch),
      }),
    );
    state = state.copyWith(playing: true);
    for (final (i, line) in rhyme.lines.indexed) {
      if (!_alive(run)) return;
      state = state.copyWith(line: i);
      for (final note in line.tune) {
        if (!_alive(run)) return;
        _audio.playNote(noteAsset(note.pitch));
        state = state.copyWith(beat: state.beat + 1);
        await Future<void>.delayed(AppDurations.rhymeBeat * note.beats);
      }
      if (!_alive(run)) return;
      await _audio.playVoiceSequence(
        [line.voice],
        debounce: false,
        owner: this,
      );
    }
    if (!_alive(run)) return;
    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(
      clearLine: true,
      playing: false,
      finished: state.finished + 1,
    );
  }

  /// Stops playing (leaving the screen does this too).
  void stop() {
    _run++;
    state = state.copyWith(clearLine: true, playing: false);
    unawaited(_audio.stopVoice(owner: this));
  }
}

final rhymeControllerProvider = NotifierProvider.autoDispose
    .family<RhymeController, RhymeState, String>(RhymeController.new);
