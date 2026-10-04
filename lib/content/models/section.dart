import 'package:flutter/foundation.dart';

import 'json_reader.dart';
import 'level.dart';

/// Learning sections. Phase 2/3 sections are added here and in
/// `assets/content/sections.json`.
enum SectionId {
  numbers,
  abc,
  animals,
  birds,
  fruits,
  vegetables,
  colours,
  shapes,
}

@immutable
class Section {
  const Section({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    required this.levels,
    required this.itemsFile,
    required this.image,
    required this.voiceEn,
    required this.voiceHi,
  });

  factory Section.fromJson(Object? json) {
    final ctx =
        'sections.json "${JsonReader(json, 'sections.json').optString('id')}"';
    final read = JsonReader(json, ctx);
    return Section(
      id: parseEnum(SectionId.values, read.string('id'), ctx),
      titleEn: read.string('title_en'),
      titleHi: read.string('title_hi'),
      levels: List.unmodifiable(
        read.stringList('levels').map((l) => parseEnum(Level.values, l, ctx)),
      ),
      itemsFile: read.string('items'),
      image: read.string('image'),
      voiceEn: read.string('voice_en'),
      voiceHi: read.string('voice_hi'),
    );
  }

  final SectionId id;
  final String titleEn;
  final String titleHi;
  final List<Level> levels;

  /// Asset path of this section's `items_*.json`.
  final String itemsFile;
  final String image;
  final String voiceEn;
  final String voiceHi;

  String title(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => titleEn,
    ContentLanguage.hi => titleHi,
  };

  String voice(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => voiceEn,
    ContentLanguage.hi => voiceHi,
  };

  Map<String, Object?> toJson() => {
    'id': id.name,
    'title_en': titleEn,
    'title_hi': titleHi,
    'levels': [for (final l in levels) l.name],
    'items': itemsFile,
    'image': image,
    'voice_en': voiceEn,
    'voice_hi': voiceHi,
  };
}
