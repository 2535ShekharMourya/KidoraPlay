import 'package:flutter/foundation.dart';

import '../spelling.dart';
import 'json_reader.dart';
import 'level.dart';
import 'section.dart';

/// One learnable thing: a number, a letter word, an animal, a bird...
@immutable
class LearningItem {
  const LearningItem({
    required this.id,
    required this.section,
    required this.levels,
    required this.wordEn,
    required this.wordHi,
    required this.image,
    required this.voiceEn,
    required this.voiceHi,
    this.letter,
    this.number,
    this.sound,
    this.factEn,
    this.factHi,
    this.voiceFactEn,
    this.voiceFactHi,
    this.letterVoice,
    this.voiceIntroEn,
    this.voiceIntroHi,
    this.riveReaction,
  });

  factory LearningItem.fromJson(Object? json, {String file = 'items'}) {
    final ctx = '$file item "${JsonReader(json, file).optString('id')}"';
    final r = JsonReader(json, ctx);
    return LearningItem(
      id: r.string('id'),
      section: parseEnum(SectionId.values, r.string('section'), ctx),
      levels: List.unmodifiable(
        r.stringList('levels').map((l) => parseEnum(Level.values, l, ctx)),
      ),
      letter: r.optString('letter'),
      number: r.optInt('number'),
      wordEn: r.string('word_en'),
      wordHi: r.string('word_hi'),
      image: r.string('image'),
      voiceEn: r.string('voice_en'),
      voiceHi: r.string('voice_hi'),
      sound: r.optString('sound'),
      factEn: r.optString('fact_en'),
      factHi: r.optString('fact_hi'),
      voiceFactEn: r.optString('voice_fact_en'),
      voiceFactHi: r.optString('voice_fact_hi'),
      letterVoice: r.optString('letter_voice'),
      voiceIntroEn: r.optString('voice_intro_en'),
      voiceIntroHi: r.optString('voice_intro_hi'),
      riveReaction: r.optString('rive_reaction'),
    );
  }

  /// Unique lowercase snake_case id; matches asset file names.
  final String id;
  final SectionId section;
  final List<Level> levels;

  /// ABC and Hindi letter items, e.g. "A" or "अ".
  final String? letter;

  /// Numbers items only, 1–100.
  final int? number;
  final String wordEn;
  final String wordHi;
  final String image;
  final String voiceEn;
  final String voiceHi;

  /// Real-world sound (animals, birds, vehicles).
  final String? sound;

  /// Short child-level fun fact ("The cow gives us milk!") and its
  /// recordings. Optional.
  final String? factEn;
  final String? factHi;
  final String? voiceFactEn;
  final String? voiceFactHi;

  /// Recording of [letter] itself when it is not an English letter
  /// (e.g. "अ").
  final String? letterVoice;

  /// "A for Apple!" / "अ से अनार!" recorded as one natural sentence.
  final String? voiceIntroEn;
  final String? voiceIntroHi;

  /// Rive state-machine input for the picture's reaction, if any.
  final String? riveReaction;

  /// Letter shown on the picture when it isn't drawn into it (Hindi).
  String? get badge => section == SectionId.hindi ? letter : null;

  /// Letter tiles for spelling mode, always derived from [wordEn].
  List<SpellingTile> get spelling => spellingOf(wordEn);

  bool isForLevel(Level level) => levels.contains(level);

  String word(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => wordEn,
    ContentLanguage.hi => wordHi,
  };

  String voice(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => voiceEn,
    ContentLanguage.hi => voiceHi,
  };

  String? factVoice(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => voiceFactEn,
    ContentLanguage.hi => voiceFactHi,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'section': section.name,
    'levels': [for (final l in levels) l.name],
    'letter': letter,
    'number': number,
    'word_en': wordEn,
    'word_hi': wordHi,
    'image': image,
    'voice_en': voiceEn,
    'voice_hi': voiceHi,
    'sound': sound,
    'fact_en': factEn,
    'fact_hi': factHi,
    'voice_fact_en': voiceFactEn,
    'voice_fact_hi': voiceFactHi,
    if (letterVoice != null) 'letter_voice': letterVoice,
    if (voiceIntroEn != null) 'voice_intro_en': voiceIntroEn,
    if (voiceIntroHi != null) 'voice_intro_hi': voiceIntroHi,
    'rive_reaction': riveReaction,
  };
}
