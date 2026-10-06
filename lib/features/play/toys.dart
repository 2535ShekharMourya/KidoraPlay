import '../../l10n/app_localizations.dart';

/// Free-play toys in the Games area (no rounds, no right or wrong).
enum ToyKind {
  /// Tap anywhere: an animal or vehicle pops up with its sound.
  tapPlay,

  /// Memory match: find the pairs.
  memory,

  /// A rainbow xylophone.
  music;

  String get image => switch (this) {
    ToyKind.tapPlay => 'assets/images/games/tap_play.webp',
    ToyKind.memory => 'assets/images/games/memory.webp',
    ToyKind.music => 'assets/images/games/music.webp',
  };

  String label(AppLocalizations l10n) => switch (this) {
    ToyKind.tapPlay => l10n.toyTapPlay,
    ToyKind.memory => l10n.toyMemory,
    ToyKind.music => l10n.toyMusic,
  };
}
