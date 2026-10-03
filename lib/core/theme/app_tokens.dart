import 'package:flutter/animation.dart';

/// Spacing tokens (logical pixels / dp).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Minimum size of any tappable target in child screens.
  static const minTapTarget = 96.0;

  /// Minimum gap between tappable targets.
  static const tapGap = 16.0;
}

/// Corner radius tokens.
abstract final class AppRadii {
  static const sm = 12.0;
  static const md = 18.0;
  static const card = 24.0;
  static const pill = 999.0;
}

/// Outline widths for the thick, friendly look.
abstract final class AppStroke {
  static const thin = 2.0;
  static const thick = 4.0;
}

/// Duration tokens. Never hardcode durations in widgets.
abstract final class AppDurations {
  static const tapFeedback = Duration(milliseconds: 180);
  static const tapDebounce = Duration(milliseconds: 250);
  static const staggerStep = Duration(milliseconds: 70);
  static const popIn = Duration(milliseconds: 600);
  static const pageTransition = Duration(milliseconds: 350);
  static const splash = Duration(milliseconds: 1800);
  static const adBreak = Duration(milliseconds: 2500);
}

/// Curve tokens.
abstract final class AppCurves {
  static const popIn = Curves.elasticOut;
  static const tap = Curves.easeOutBack;
  static const page = Curves.easeOutCubic;
}

/// Scale factors for tap "juice".
abstract final class AppScale {
  static const tapPeak = 1.15;
}
