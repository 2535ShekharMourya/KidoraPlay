import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/learning_item.dart';
import '../../content/models/level.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_catalog.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/settings/app_settings.dart';

/// Speaks Kido's lines from `kido_lines.json` in his talk language
/// (Hindi in bilingual mode), unless [languages] is given.
///
/// Placeholders in a line's audio are filled with real recordings:
/// `{item}` → the item's word, `{letter}` → a letter clip, `{n}` → the
/// number's name, `{section}` → the section's name. Lines with several variants (praise) are picked at
/// random, never the same one twice in a row.
class KidoVoice {
  KidoVoice(this._ref, {math.Random? random})
    : _random = random ?? math.Random();

  final Ref _ref;
  final math.Random _random;
  final _lastVariant = <String, int>{};

  /// Builds the clip list for [event]. Exposed for tests.
  List<String> clipsFor(
    String event, {
    List<ContentLanguage>? languages,
    LearningItem? item,
    String? itemAudio,
    String? letterAudio,
    int? n,
    Section? section,
  }) {
    final catalog = _ref.read(contentCatalogProvider).value;
    if (catalog == null) return const [];
    final langs =
        languages ?? _ref.read(settingsProvider).language.talkLanguages;
    return [
      for (final lang in langs)
        ..._clipsForLanguage(
          catalog,
          event,
          lang,
          item: item,
          itemAudio: itemAudio,
          letterAudio: letterAudio,
          n: n,
          section: section,
        ),
    ];
  }

  /// Says [event]. Returns true if it played to the end.
  Future<bool> say(
    String event, {
    List<ContentLanguage>? languages,
    LearningItem? item,
    String? itemAudio,
    String? letterAudio,
    int? n,
    Section? section,
    Object? owner,
  }) async {
    final clips = clipsFor(
      event,
      languages: languages,
      item: item,
      itemAudio: itemAudio,
      letterAudio: letterAudio,
      n: n,
      section: section,
    );
    if (clips.isEmpty) return false;
    return _ref
        .read(audioServiceProvider)
        .playVoiceSequence(clips, debounce: false, owner: owner);
  }

  List<String> _clipsForLanguage(
    ContentCatalog catalog,
    String event,
    ContentLanguage lang, {
    LearningItem? item,
    String? itemAudio,
    String? letterAudio,
    int? n,
    Section? section,
  }) {
    final variants = catalog.kidoLines.variants(event, lang);
    if (variants.isEmpty) return const [];
    final line = variants[_pick('$event/${lang.name}', variants.length)];

    String? resolve(String placeholder) => switch (placeholder) {
      '{item}' => itemAudio ?? item?.voice(lang),
      '{letter}' => letterAudio,
      '{n}' => n == null ? null : _numberItem(catalog, n)?.voice(lang),
      '{section}' => section?.voice(lang),
      _ => null,
    };

    return [
      for (final segment in line.audio)
        if (!KidoLine.isPlaceholder(segment)) segment else ?resolve(segment),
    ];
  }

  int _pick(String key, int count) {
    if (count == 1) return 0;
    final last = _lastVariant[key];
    var next = _random.nextInt(count);
    if (next == last) next = (next + 1 + _random.nextInt(count - 1)) % count;
    _lastVariant[key] = next;
    return next;
  }

  static LearningItem? _numberItem(ContentCatalog catalog, int n) {
    for (final i in catalog.itemsFor(SectionId.numbers)) {
      if (i.number == n) return i;
    }
    return null;
  }
}

final kidoVoiceProvider = Provider<KidoVoice>(KidoVoice.new);
