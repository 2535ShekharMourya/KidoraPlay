import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/level.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_catalog.dart';
import '../../content/repository/content_repository.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/local_store.dart';
import '../games/quiz_models.dart';
import '../play/toys.dart';
import '../progress/progress_controller.dart';

/// One step on today's path.
enum PathKind { learn, game, trace, toy }

@immutable
class PathStep {
  const PathStep(this.kind, this.ref);

  /// "learn:cow", "game:findIt", "trace:a_apple", "toy:tapPlay".
  factory PathStep.parse(String key) {
    final (kind, ref) = switch (key.split(':')) {
      [final k, final r] => (k, r),
      _ => ('', ''),
    };
    return PathStep(PathKind.values.asNameMap()[kind] ?? PathKind.toy, ref);
  }

  final PathKind kind;

  /// An item id, a game or toy name.
  final String ref;

  String get key => '${kind.name}:$ref';

  @override
  bool operator ==(Object other) => other is PathStep && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

@immutable
class DailyPathState {
  const DailyPathState({
    this.day = '',
    this.steps = const [],
    this.done = const {},
    this.trophies = 0,
    this.celebrations = 0,
  });

  /// The local date this path is for (yyyy-mm-dd).
  final String day;
  final List<PathStep> steps;
  final Set<String> done;

  /// Paths finished, ever (shown on the path; never a streak).
  final int trophies;

  /// Increments when today's path is finished (celebration).
  final int celebrations;

  bool isDone(PathStep step) => done.contains(step.key);

  /// The first step not done yet, or null when all are done.
  int? get current {
    for (final (i, s) in steps.indexed) {
      if (!isDone(s)) return i;
    }
    return null;
  }

  bool get finished => steps.isNotEmpty && current == null;

  DailyPathState copyWith({
    Set<String>? done,
    int? trophies,
    int? celebrations,
  }) => DailyPathState(
    day: day,
    steps: steps,
    done: done ?? this.done,
    trophies: trophies ?? this.trophies,
    celebrations: celebrations ?? this.celebrations,
  );
}

/// Today's date; tests replace it.
final pathClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Builds a day's five steps for [level]: two new cards, a game, another
/// new card, then tracing (or a toy for babies). The same day always
/// gives the same path; tomorrow brings a new one.
List<PathStep> buildPath({
  required ContentCatalog catalog,
  required Level level,
  required Set<String> learned,
  required String day,
}) {
  final random = math.Random(day.hashCode ^ level.index);
  final sections = [
    for (final s in catalog.sectionsFor(level))
      if (catalog.itemsFor(s.id, level: level).isNotEmpty) s.id,
  ]..shuffle(random);

  // New words first (not learned yet), from different sections.
  LearningItem? pick(SectionId section) {
    final items = catalog.itemsFor(section, level: level);
    final fresh = items.where((i) => !learned.contains(i.id)).toList();
    final from = fresh.isNotEmpty ? fresh : items;
    return from.isEmpty ? null : from[random.nextInt(from.length)];
  }

  final cards = <PathStep>[];
  for (final s in sections) {
    final item = pick(s);
    if (item != null) cards.add(PathStep(PathKind.learn, item.id));
    if (cards.length == 3) break;
  }

  final games = [
    for (final g in GameKind.values)
      if (g != GameKind.letters || level != Level.baby) g,
  ];
  final game = PathStep(
    PathKind.game,
    games[random.nextInt(games.length)].name,
  );

  final PathStep last;
  if (level == Level.baby) {
    const toys = [ToyKind.tapPlay, ToyKind.music];
    last = PathStep(PathKind.toy, toys[random.nextInt(toys.length)].name);
  } else {
    // Write a letter (or a number up to 20).
    final traceable = [
      ...catalog.itemsFor(SectionId.abc, level: level),
      for (final n in catalog.itemsFor(SectionId.numbers, level: level))
        if ((n.number ?? 99) <= 20) n,
    ];
    last = traceable.isEmpty
        ? const PathStep(PathKind.toy, 'music')
        : PathStep(
            PathKind.trace,
            traceable[random.nextInt(traceable.length)].id,
          );
  }

  return [...cards.take(2), game, ...cards.skip(2), last];
}

/// Kido's daily path: five short steps a day, ticked off as the child
/// finishes them anywhere in the app. Saved on the device. No streaks: a
/// missed day costs nothing.
class DailyPathController extends Notifier<DailyPathState> {
  static const _dayKey = 'path.day';
  static const _stepsKey = 'path.steps';
  static const _doneKey = 'path.done';
  static const _trophiesKey = 'path.trophies';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  DailyPathState build() {
    final today = dayKey(ref.watch(pathClockProvider)());
    final level = ref.watch(settingsProvider.select((s) => s.level));
    final store = ref.watch(localStoreProvider);
    final trophies = int.tryParse(store.getString(_trophiesKey) ?? '') ?? 0;
    final savedDay = store.getString(_dayKey);
    final savedLevel = store.getString('$_dayKey.level');
    if (savedDay == today && savedLevel == level.name) {
      return DailyPathState(
        day: today,
        steps: [
          for (final k in store.getStringList(_stepsKey)) PathStep.parse(k),
        ],
        done: store.getStringList(_doneKey).toSet(),
        trophies: trophies,
      );
    }
    final catalog = ref.watch(contentCatalogProvider).value;
    if (catalog == null) return DailyPathState(day: today, trophies: trophies);
    final steps = buildPath(
      catalog: catalog,
      level: level,
      learned: ref.read(progressProvider).learned,
      day: today,
    );
    // Saved after this build (writing during build would re-trigger it).
    Future.microtask(() async {
      await store.setString(_dayKey, today);
      await store.setString('$_dayKey.level', level.name);
      await store.setStringList(_stepsKey, [for (final s in steps) s.key]);
      await store.setStringList(_doneKey, const []);
    });
    return DailyPathState(day: today, steps: steps, trophies: trophies);
  }

  /// Something was finished somewhere in the app; ticks it off if it is
  /// one of today's steps.
  Future<void> completed(PathStep step) async {
    if (!state.steps.contains(step) || state.isDone(step)) return;
    final done = {...state.done, step.key};
    state = state.copyWith(done: done);
    await _store.setStringList(_doneKey, done.toList());
    if (state.finished) {
      final trophies = state.trophies + 1;
      state = state.copyWith(
        trophies: trophies,
        celebrations: state.celebrations + 1,
      );
      await _store.setString(_trophiesKey, '$trophies');
    }
  }
}

final dailyPathProvider = NotifierProvider<DailyPathController, DailyPathState>(
  DailyPathController.new,
);
