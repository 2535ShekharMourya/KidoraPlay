import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/settings/app_settings.dart';

/// A list of items the child moves through: a whole section, or one row of
/// ten numbers (row 1 = 1–10 … row 10 = 91–100).
typedef ItemScope = ({SectionId section, int? row});

/// Numbers row (1–10) of [number].
int numberRowOf(int number) => (number - 1) ~/ 10 + 1;

/// Items in [ItemScope], filtered to the selected class level.
final scopeItemsProvider =
    Provider.family<List<LearningItem>, ItemScope>((ref, scope) {
  final catalog = ref.watch(contentCatalogProvider).value;
  if (catalog == null) return const [];
  final level = ref.watch(settingsProvider.select((s) => s.level));
  final items = catalog.itemsFor(scope.section, level: level);
  final row = scope.row;
  if (row == null) return items;
  return [
    for (final i in items)
      if (i.number != null && numberRowOf(i.number!) == row) i,
  ];
});

/// Number rows that have items at the selected level (Nursery: 1–2).
final numberRowsProvider = Provider<List<int>>((ref) {
  final items =
      ref.watch(scopeItemsProvider((section: SectionId.numbers, row: null)));
  return {for (final i in items) if (i.number != null) numberRowOf(i.number!)}
      .toList()
    ..sort();
});
