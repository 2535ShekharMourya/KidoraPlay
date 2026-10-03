import 'package:flutter/foundation.dart';

import 'json_reader.dart';
import 'level.dart';

/// Event keys in `kido_lines.json`.
abstract final class KidoEvent {
  static const welcomeFirst = 'welcome_first';
  static const welcomeBack = 'welcome_back';
  static const hintTap = 'hint_tap';
  static const spellTogether = 'spell_together';
  static const praise = 'praise';
  static const tryAgain = 'try_again';
  static const sectionDone = 'section_done';
  static const goodbye = 'goodbye';

  static const all = [
    welcomeFirst,
    welcomeBack,
    hintTap,
    spellTogether,
    praise,
    tryAgain,
    sectionDone,
    goodbye,
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
