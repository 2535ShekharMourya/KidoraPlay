import '../../l10n/app_localizations.dart';

/// Free-play toys in the Games area (no rounds, no right or wrong).
enum ToyKind {
  /// Tap anywhere: an animal or vehicle pops up with its sound.
  tapPlay;

  String get image => switch (this) {
    ToyKind.tapPlay => 'assets/images/games/tap_play.webp',
  };

  String label(AppLocalizations l10n) => switch (this) {
    ToyKind.tapPlay => l10n.toyTapPlay,
  };
}
