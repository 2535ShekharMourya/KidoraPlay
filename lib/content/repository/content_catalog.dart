import 'package:flutter/foundation.dart';

import '../models/kido_line.dart';
import '../models/learning_item.dart';
import '../models/level.dart';
import '../models/section.dart';

/// All loaded content, with level filtering.
@immutable
class ContentCatalog {
  ContentCatalog({
    required List<Section> sections,
    required Map<SectionId, List<LearningItem>> items,
    required this.kidoLines,
  }) : sections = List<Section>.unmodifiable(sections),
       _items = Map<SectionId, List<LearningItem>>.unmodifiable({
         for (final e in items.entries)
           e.key: List<LearningItem>.unmodifiable(e.value),
       });

  final List<Section> sections;
  final Map<SectionId, List<LearningItem>> _items;
  final KidoLines kidoLines;

  Iterable<LearningItem> get allItems => _items.values.expand((l) => l);

  Section? section(SectionId id) {
    for (final s in sections) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Sections shown for [level], in `sections.json` order.
  List<Section> sectionsFor(Level level) => [
    for (final s in sections)
      if (s.levels.contains(level)) s,
  ];

  /// Items of [section], optionally filtered to [level].
  List<LearningItem> itemsFor(SectionId section, {Level? level}) {
    final items = _items[section] ?? const [];
    if (level == null) return items;
    return [
      for (final i in items)
        if (i.isForLevel(level)) i,
    ];
  }

  LearningItem? itemById(String id) {
    for (final i in allItems) {
      if (i.id == id) return i;
    }
    return null;
  }
}
