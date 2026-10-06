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

  /// Smallest spelling tile, used only when a long word (e.g.
  /// "Seventy-seven") cannot fit at [minTapTarget].
  static const minLetterTile = 44.0;
}

/// Screen layout zones (landscape).
abstract final class AppLayout {
  /// Left and right columns kept free for the back/arrow buttons. The
  /// bottom of the left column is Kido's spot, so content never sits under
  /// him.
  static const sideZone = AppSpacing.minTapTarget + AppSpacing.md * 2;

  /// Screens with a shorter side above this (tablets) are laid out at
  /// this height and scaled up, up to [maxScale].
  static const designShortSide = 420.0;
  static const maxScale = 2.0;

  /// Home section tiles hold a picture, a name and progress.
  static const sectionTileMinHeight = 120.0;

  /// Kido waving on the splash screen.
  static const splashKido = 150.0;

  /// Star slots on a learn card.
  static const starMeter = 36.0;

  /// Items per page in a section grid (5 × 2). Paging uses big arrow
  /// buttons because child screens never scroll or swipe.
  static const gridColumns = 5;
  static const gridRows = 2;

  /// Kido's height as a share of screen height (spec: 18–22%).
  static const kidoHeightFraction = 0.2;

  /// Kido's width / height.
  static const kidoAspect = 1.2;
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

  /// Per-letter rhythm when there is no sound (muted or missing audio).
  static const silentSegment = Duration(milliseconds: 450);
  static const wiggle = Duration(milliseconds: 180);
  static const kidoIdle = Duration(milliseconds: 2600);
  static const kidoTalk = Duration(milliseconds: 240);
  static const kidoHold = Duration(milliseconds: 450);
  static const beckon = Duration(milliseconds: 700);

  /// Quiet gap after "Say it with me… Apple!" for the child to repeat.
  static const echoPause = Duration(milliseconds: 1600);

  /// Learn cards: idle hints come sooner while the child discovers by
  /// tapping (look → point + "Tap the apple!" → glow).
  static const discoverLook = Duration(seconds: 6);
  static const discoverPoint = Duration(seconds: 12);
  static const discoverGlow = Duration(seconds: 18);

  /// Count along up to this number on number cards (longer gets tiring).
  static const countAlongMax = 20;

  /// Pauses between spelled letters and counted numbers, so a child can
  /// follow (and say along).
  static const spellGap = Duration(milliseconds: 550);
  static const countGap = Duration(milliseconds: 350);
  static const stickerFlight = Duration(milliseconds: 900);
  static const celebration = Duration(milliseconds: 3500);
  static const quizNext = Duration(milliseconds: 600);

  /// Tracing: idle time before Kido shows the stroke again, and how long
  /// one demo of a stroke takes.
  static const traceIdle = Duration(seconds: 7);

  /// Balloon party: one balloon's rise, the whole party at most, and
  /// the pause after the last pop.
  static const balloonRise = Duration(seconds: 7);

  /// Tap & Play: how long a popped-up friend stays before floating off.
  static const tapPlayLife = Duration(milliseconds: 3200);

  /// Kido's Room: a fruit's flight to his mouth, and a bath's bubbles.
  static const roomFeed = Duration(milliseconds: 650);
  static const roomBath = Duration(milliseconds: 2600);

  /// One beat of a rhyme's tune.
  static const rhymeBeat = Duration(milliseconds: 320);

  /// Memory match: how long two different cards stay up, and a flip.
  static const memoryLook = Duration(milliseconds: 1300);
  static const cardFlip = Duration(milliseconds: 260);
  static const balloonParty = Duration(seconds: 15);
  static const balloonLastPop = Duration(milliseconds: 1400);
  static const traceDemo = Duration(milliseconds: 1800);
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

  /// Balloons in a balloon party.
  static const balloons = 6;
}
