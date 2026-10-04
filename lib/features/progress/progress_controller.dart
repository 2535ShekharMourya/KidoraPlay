import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';
import '../../core/storage/local_store.dart';
import '../section_grid/section_items.dart';

/// Which items the child has learned (completed the "you do" step).
/// Each learned item is a sticker in the sticker book. Stored on the
/// device only.
@immutable
class ProgressState {
  const ProgressState(this.learned);

  final Set<String> learned;

  bool isLearned(String itemId) => learned.contains(itemId);

  int learnedOf(Iterable<LearningItem> items) =>
      items.where((i) => learned.contains(i.id)).length;
}

/// Result of learning an item.
typedef LearnResult = ({bool newSticker, bool completedScope});

class ProgressNotifier extends Notifier<ProgressState> {
  static const _key = 'progress.learned';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  ProgressState build() =>
      ProgressState(ref.watch(localStoreProvider).getStringList(_key).toSet());

  /// Records [item] as learned. [completedScope] is true when this item
  /// was the last one missing in [scope] (a numbers row or a section),
  /// which earns the big celebration.
  Future<LearnResult> markLearned(LearningItem item, ItemScope scope) async {
    final items = ref.read(scopeItemsProvider(scope));
    final wasComplete = _complete(items, state.learned);
    final newSticker = !state.learned.contains(item.id);
    if (newSticker) {
      state = ProgressState({...state.learned, item.id});
      await _store.setStringList(_key, state.learned.toList()..sort());
    }
    final completedScope =
        !wasComplete && items.isNotEmpty && _complete(items, state.learned);
    return (newSticker: newSticker, completedScope: completedScope);
  }

  static bool _complete(List<LearningItem> items, Set<String> learned) =>
      items.every((i) => learned.contains(i.id));
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(
  ProgressNotifier.new,
);

/// (learned, total) for a whole section at the selected class level.
final sectionProgressProvider =
    Provider.family<({int learned, int total}), SectionId>((ref, section) {
      final items = ref.watch(
        scopeItemsProvider((section: section, row: null)),
      );
      final progress = ref.watch(progressProvider);
      return (learned: progress.learnedOf(items), total: items.length);
    });
