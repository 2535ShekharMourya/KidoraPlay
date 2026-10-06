import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/json_reader.dart';
import '../../content/models/level.dart';

/// One page of a picture story.
@immutable
class StoryPage {
  const StoryPage({
    required this.image,
    required this.textEn,
    required this.textHi,
    required this.voiceEn,
    required this.voiceHi,
  });

  factory StoryPage.fromJson(Object? json, String where) {
    final r = JsonReader(json, where);
    return StoryPage(
      image: r.string('image'),
      textEn: r.string('text_en'),
      textHi: r.string('text_hi'),
      voiceEn: r.string('voice_en'),
      voiceHi: r.string('voice_hi'),
    );
  }

  final String image;
  final String textEn;
  final String textHi;
  final String voiceEn;
  final String voiceHi;

  String text(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => textEn,
    ContentLanguage.hi => textHi,
  };

  String voice(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => voiceEn,
    ContentLanguage.hi => voiceHi,
  };
}

/// A short picture story read aloud (from `assets/content/stories.json`,
/// made by `tool/make_stories.py`).
@immutable
class Story {
  const Story({
    required this.id,
    required this.levels,
    required this.titleEn,
    required this.titleHi,
    required this.cover,
    required this.voiceTitleEn,
    required this.voiceTitleHi,
    required this.pages,
  });

  factory Story.fromJson(Object? json) {
    final where =
        'stories.json story "${JsonReader(json, 'stories.json').optString('id')}"';
    final r = JsonReader(json, where);
    final pages = r.list('pages');
    return Story(
      id: r.string('id'),
      levels: List.unmodifiable(
        r.stringList('levels').map((l) => parseEnum(Level.values, l, where)),
      ),
      titleEn: r.string('title_en'),
      titleHi: r.string('title_hi'),
      cover: r.string('cover'),
      voiceTitleEn: r.string('voice_title_en'),
      voiceTitleHi: r.string('voice_title_hi'),
      pages: List.unmodifiable([
        for (final (i, p) in pages.indexed)
          StoryPage.fromJson(p, '$where page ${i + 1}'),
      ]),
    );
  }

  final String id;
  final List<Level> levels;
  final String titleEn;
  final String titleHi;
  final String cover;
  final String voiceTitleEn;
  final String voiceTitleHi;
  final List<StoryPage> pages;

  String title(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => titleEn,
    ContentLanguage.hi => titleHi,
  };

  String titleVoice(ContentLanguage lang) => switch (lang) {
    ContentLanguage.en => voiceTitleEn,
    ContentLanguage.hi => voiceTitleHi,
  };

  /// Every asset the story needs (for validation).
  Iterable<String> get assets sync* {
    yield cover;
    yield voiceTitleEn;
    yield voiceTitleHi;
    for (final p in pages) {
      yield p.image;
      yield p.voiceEn;
      yield p.voiceHi;
    }
  }
}

Future<List<Story>> loadStories(AssetBundle bundle) async {
  final raw = await bundle.loadString('assets/content/stories.json');
  return List.unmodifiable([
    for (final s in jsonDecode(raw) as List) Story.fromJson(s),
  ]);
}

final storiesProvider = FutureProvider<List<Story>>(
  (ref) => loadStories(rootBundle),
);
