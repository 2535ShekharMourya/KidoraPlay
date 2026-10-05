import '../models/kido_line.dart';
import '../models/learning_item.dart';
import '../models/level.dart';
import '../models/section.dart';
import '../number_names.dart';
import 'content_catalog.dart';

/// Thrown in debug builds when content fails validation.
class ContentValidationException implements Exception {
  ContentValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() =>
      'Content validation failed with ${errors.length} '
      'error(s):\n${errors.map((e) => '  - $e').join('\n')}';
}

final _idPattern = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
final _wordPattern = RegExp(r'^[A-Za-z]+([ -][A-Za-z]+)*$');
final _letterPattern = RegExp(r'^[A-Z]$');
final _devanagari = RegExp(r'^[\u0900-\u097F]+$');

/// Checks content for mistakes. [assets] is every bundled asset path.
/// Returns a list of human-readable errors (empty when valid).
List<String> validateContent(
  ContentCatalog catalog, {
  required Set<String> assets,
}) {
  final errors = <String>[];

  void requireAsset(String where, String field, String? path) {
    if (path == null) return;
    if (path.trim().isEmpty) {
      errors.add('$where: "$field" is empty');
    } else if (!assets.contains(path)) {
      errors.add('$where: "$field" file not found: $path');
    }
  }

  // Sections
  final sectionIds = <SectionId>{};
  for (final s in catalog.sections) {
    final where = 'section "${s.id.name}"';
    if (!sectionIds.add(s.id)) errors.add('$where: duplicate section id');
    if (s.titleEn.trim().isEmpty) errors.add('$where: "title_en" is empty');
    if (s.titleHi.trim().isEmpty) errors.add('$where: "title_hi" is empty');
    if (s.levels.isEmpty) errors.add('$where: "levels" is empty');
    requireAsset(where, 'image', s.image);
    requireAsset(where, 'voice_en', s.voiceEn);
    requireAsset(where, 'voice_hi', s.voiceHi);
    if (catalog.itemsFor(s.id).isEmpty) errors.add('$where: has no items');
  }

  // Items
  final seenIds = <String>{};
  for (final s in catalog.sections) {
    for (final item in catalog.itemsFor(s.id)) {
      errors.addAll(_validateItem(item, s.id, seenIds));
      final where = 'item "${item.id}"';
      requireAsset(where, 'image', item.image);
      requireAsset(where, 'voice_en', item.voiceEn);
      requireAsset(where, 'voice_hi', item.voiceHi);
      requireAsset(where, 'sound', item.sound);
      requireAsset(where, 'voice_fact_en', item.voiceFactEn);
      requireAsset(where, 'voice_fact_hi', item.voiceFactHi);
      requireAsset(where, 'letter_voice', item.letterVoice);
      for (final tile in item.spelling) {
        if (tile.audioAsset case final audio?) {
          requireAsset(where, 'letter ${tile.char} audio', audio);
        }
      }
    }
  }

  // Kido lines
  final lines = catalog.kidoLines;
  for (final event in KidoEvent.all) {
    for (final lang in ContentLanguage.values) {
      final where = 'kido line "$event" (${lang.name})';
      final variants = lines.variants(event, lang);
      if (variants.isEmpty) {
        errors.add('$where: missing');
        continue;
      }
      for (final v in variants) {
        if (v.text.trim().isEmpty) errors.add('$where: "text" is empty');
        if (v.audio.isEmpty) errors.add('$where: "audio" is empty');
        for (final segment in v.audio) {
          if (KidoLine.isPlaceholder(segment)) {
            if (!v.text.contains(segment)) {
              errors.add('$where: audio placeholder $segment not in text');
            }
          } else {
            requireAsset(where, 'audio', segment);
          }
        }
      }
    }
  }

  return errors;
}

List<String> _validateItem(
  LearningItem item,
  SectionId fileSection,
  Set<String> seenIds,
) {
  final where = 'item "${item.id}"';
  final errors = <String>[];

  if (!_idPattern.hasMatch(item.id)) {
    errors.add('$where: id must be lowercase snake_case');
  }
  if (!seenIds.add(item.id)) errors.add('$where: duplicate id');
  if (item.section != fileSection) {
    errors.add(
      '$where: section is "${item.section.name}" but it is listed in '
      'the "${fileSection.name}" items file',
    );
  }
  if (item.levels.isEmpty) errors.add('$where: "levels" is empty');
  if (item.wordHi.trim().isEmpty) errors.add('$where: "word_hi" is empty');
  if (item.wordEn.trim().isEmpty) {
    errors.add('$where: "word_en" is empty');
  } else if (!_wordPattern.hasMatch(item.wordEn)) {
    errors.add(
      '$where: "word_en" may only contain letters, single spaces and '
      'hyphens (it is used for spelling): "${item.wordEn}"',
    );
  }
  final hasFact = [
    item.factEn,
    item.factHi,
    item.voiceFactEn,
    item.voiceFactHi,
  ].where((f) => f != null && f.trim().isNotEmpty).length;
  if (hasFact != 0 && hasFact != 4) {
    errors.add(
      '$where: a fact needs fact_en, fact_hi, voice_fact_en and '
      'voice_fact_hi together',
    );
  }
  for (final (field, path) in [
    ('voice_fact_en', item.voiceFactEn),
    ('voice_fact_hi', item.voiceFactHi),
  ]) {
    if (path != null && !path.split('/').last.startsWith('${item.id}_fact')) {
      errors.add('$where: "$field" file name must be ${item.id}_fact');
    }
  }
  if (!item.image.endsWith('.webp')) {
    errors.add('$where: "image" must be a .webp file');
  }
  for (final (field, path) in [
    ('image', item.image),
    ('voice_en', item.voiceEn),
    ('voice_hi', item.voiceHi),
    if (item.sound case final sound?) ('sound', sound),
  ]) {
    final name = path.split('/').last.split('.').first;
    if (name != item.id) {
      errors.add('$where: "$field" file name must match the id: $path');
    }
  }

  switch (item.section) {
    case SectionId.numbers:
      final n = item.number;
      if (n == null || n < 1 || n > 100) {
        errors.add('$where: "number" must be 1–100');
      } else if (item.wordEn != numberNameEn(n)) {
        errors.add('$where: "word_en" should be "${numberNameEn(n)}" for $n');
      }
    case SectionId.abc:
      final letter = item.letter;
      if (letter == null || !_letterPattern.hasMatch(letter)) {
        errors.add('$where: "letter" must be one capital letter A–Z');
      } else if (!item.wordEn.toUpperCase().startsWith(letter)) {
        errors.add('$where: "word_en" must start with "$letter"');
      }
    case SectionId.animals || SectionId.birds || SectionId.vehicles:
      if (item.sound == null) errors.add('$where: "sound" is required');
    case SectionId.hindi:
      if (item.letter == null || item.letter!.trim().isEmpty) {
        errors.add('$where: "letter" is required');
      } else if (!_devanagari.hasMatch(item.letter!)) {
        errors.add('$where: "letter" must be Devanagari');
      }
      if (item.letterVoice == null) {
        errors.add('$where: "letter_voice" is required');
      }
    case SectionId.fruits ||
        SectionId.vegetables ||
        SectionId.colours ||
        SectionId.shapes:
      break;
  }

  return errors;
}
