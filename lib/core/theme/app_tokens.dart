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
  static const pressDown = Duration(milliseconds: 80);
  static const tapBounce = Duration(milliseconds: 380);
  static const tapDebounce = Duration(milliseconds: 250);
  static const staggerStep = Duration(milliseconds: 70);
  static const popIn = Duration(milliseconds: 700);
  static const highlight = Duration(milliseconds: 260);
  static const sparkle = Duration(milliseconds: 650);
  static const confetti = Duration(milliseconds: 2200);
  static const idleFloat = Duration(milliseconds: 2600);
  static const backgroundLoop = Duration(seconds: 40);
  static const pageTransition = Duration(milliseconds: 350);
  static const splash = Duration(milliseconds: 1800);
  static const adBreak = Duration(milliseconds: 2500);
}

/// Curve tokens.
abstract final class AppCurves {
  static const popIn = Curves.elasticOut;
  static const tap = Curves.easeOutBack;
  static const tapSettle = Curves.elasticOut;
  static const page = Curves.easeOutCubic;
}

/// Scale factors and offsets for "juice".
abstract final class AppScale {
  static const pressed = 0.94;
  static const tapPeak = 1.15;
  static const highlighted = 1.15;
  static const idleFloatOffset = 5.0;
}

/// Particle counts for bursts.
abstract final class AppParticles {
  static const sparkle = 12;
  static const confetti = 70;
}
