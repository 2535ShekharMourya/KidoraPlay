/// When an interstitial may be shown (CLAUDE.md §2, rules 7–12).
///
/// Ads are only ever *offered* at natural breaks (a finished section or
/// game); these rules then say no unless the timing is gentle enough.
abstract final class AdRules {
  /// No ad in the first minutes of a session.
  static const sessionGrace = Duration(minutes: 3);

  /// At least this long between two ads.
  static const minInterval = Duration(minutes: 4);

  static bool canShow({
    required bool premium,
    required DateTime sessionStart,
    required DateTime now,
    DateTime? lastShown,
  }) {
    if (premium) return false;
    if (now.difference(sessionStart) < sessionGrace) return false;
    if (lastShown != null && now.difference(lastShown) < minInterval) {
      return false;
    }
    return true;
  }
}
