import 'package:flutter/foundation.dart';

import 'json_reader.dart';
import 'level.dart';

/// Event keys in `kido_lines.json`.
abstract final class KidoEvent {
  static const welcomeFirst = 'welcome_first';
  static const welcomeBack = 'welcome_back';
  static const sectionIntro = 'section_intro';

  /// "Look!": grabs attention before showing something new.
  static const look = 'look';

  /// "A for Apple!" (`{letter}`, `{item}`).
  static const letterFor = 'letter_for';

  /// "Listen to the cow!" before an animal sound.
  static const listenSound = 'listen_sound';
  static const letsCount = 'lets_count';

  /// "Say it with me!": the child repeats the word (echo).
  static const sayWithMe = 'say_with_me';

  /// Short cheer after the child's turn.
  static const yay = 'yay';
  static const spellTogether = 'spell_together';

  /// "Tap A!" during "we do".
  static const tapLetter = 'tap_letter';

  /// "Where is the apple? Can you tap it?" ("you do").
  static const findIt = 'find_it';

  /// "Here it is! Tap the apple!" (idle hint).
  static const hintTap = 'hint_tap';
  static const praise = 'praise';

  /// "Tap the picture, and see what happens!" (first visit to a section).
  static const tapToPlay = 'tap_to_play';

  /// "Let's see the next one!" after a card's stars are all earned.
  static const nextOne = 'next_one';

  /// "Balloon party! Pop the balloons!" (every few cards).
  static const balloonParty = 'balloon_party';

  /// "Let's learn to spell Tractor!" before the letters.
  static const letsSpell = 'lets_spell';

  /// Number cards: "Let's count the stars!" … "How many stars? Three!".
  static const countStars = 'count_stars';
  static const howManyStars = 'how_many_stars';
  static const tryAgain = 'try_again';
  static const sectionDone = 'section_done';
  static const goodbye = 'goodbye';

  // Games.
  static const letsPlay = 'lets_play';
  static const whoSays = 'who_says';
  static const howMany = 'how_many';
  static const findLetter = 'find_letter';

  /// "That's a dog!": names a different choice, never "wrong".
  static const thatsA = 'thats_a';
  static const gameDone = 'game_done';

  // Finger tracing.
  /// "Let's write A!"
  static const traceIt = 'trace_it';

  /// "Start at the green dot, and follow me!" (idle hint).
  static const traceHint = 'trace_hint';

  /// "You wrote A!"
  static const traceDone = 'trace_done';

  static const all = [
    welcomeFirst,
    welcomeBack,
    sectionIntro,
    look,
    letterFor,
    listenSound,
    letsCount,
    sayWithMe,
    yay,
    spellTogether,
    tapLetter,
    findIt,
    hintTap,
    praise,
    tapToPlay,
    nextOne,
    balloonParty,
    letsSpell,
    countStars,
    howManyStars,
    tryAgain,
    sectionDone,
    goodbye,
    letsPlay,
    whoSays,
    howMany,
    findLetter,
    thatsA,
    gameDone,
    traceIt,
    traceHint,
    traceDone,
  ];
}

/// One spoken variant of a Kido event.
///
/// [audio] is played in sequence. Segments like `{item}`, `{n}` or
/// `{section}` are placeholders filled at runtime with the matching item's
/// or section's own recording.
@immutable
class KidoLine {
  const KidoLine({required this.text, required this.audio});

  factory KidoLine.fromJson(Object? json, String context) {
    final r = JsonReader(json, context);
    return KidoLine(text: r.string('text'), audio: r.stringList('audio'));
  }

  final String text;
  final List<String> audio;

  static bool isPlaceholder(String segment) =>
      segment.startsWith('{') && segment.endsWith('}');

  Iterable<String> get audioFiles => audio.where((s) => !isPlaceholder(s));

  Map<String, Object?> toJson() => {'text': text, 'audio': audio};
}

/// All Kido voice lines, keyed by event then language.
@immutable
class KidoLines {
  const KidoLines(this._events);

  factory KidoLines.fromJson(Object? json) {
    const file = 'kido_lines.json';
    final root = JsonReader(json, file);
    final events = <String, Map<ContentLanguage, List<KidoLine>>>{};
    for (final event in root.keys) {
      final ctx = '$file "$event"';
      final byLang = JsonReader(root.object(event), ctx);
      events[event] = {
        for (final lang in ContentLanguage.values)
          lang: List.unmodifiable(
            byLang
                .list(lang.name)
                .map((v) => KidoLine.fromJson(v, '$ctx ${lang.name}')),
          ),
      };
    }
    return KidoLines(Map.unmodifiable(events));
  }

  final Map<String, Map<ContentLanguage, List<KidoLine>>> _events;

  Iterable<String> get events => _events.keys;

  List<KidoLine> variants(String event, ContentLanguage lang) =>
      _events[event]?[lang] ?? const [];
}
