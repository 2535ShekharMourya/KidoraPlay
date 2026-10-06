import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../path/daily_path.dart';
import 'toys.dart';

/// A colouring page: areas (drawn in a 4:3 box, 0–1 coordinates) the
/// child fills by tapping. Later areas lie on top of earlier ones.
@immutable
class ColouringPage {
  const ColouringPage(this.id, this.areas);

  final String id;
  final List<Path Function(Size)> areas;
}

Rect _r(Size s, double l, double t, double w, double h) =>
    Rect.fromLTWH(s.width * l, s.height * t, s.width * w, s.height * h);

Path _oval(Size s, double l, double t, double w, double h) =>
    Path()..addOval(_r(s, l, t, w, h));

Path _box(Size s, double l, double t, double w, double h, [double r = 0.02]) =>
    Path()..addRRect(
      RRect.fromRectAndRadius(_r(s, l, t, w, h), Radius.circular(s.height * r)),
    );

Path _poly(Size s, List<(double, double)> points) => Path()
  ..addPolygon([
    for (final (x, y) in points) Offset(s.width * x, s.height * y),
  ], true);

/// Six pages with big, easy areas.
final colouringPages = <ColouringPage>[
  ColouringPage('house', [
    (s) => _oval(s, 0.74, 0.05, 0.18, 0.24), // sun
    (s) => _box(s, 0.22, 0.42, 0.46, 0.46), // wall
    (s) => _poly(s, [(0.16, 0.44), (0.45, 0.12), (0.74, 0.44)]), // roof
    (s) => _box(s, 0.39, 0.62, 0.12, 0.26), // door
    (s) => _box(s, 0.27, 0.5, 0.09, 0.1), // window
    (s) => _box(s, 0.54, 0.5, 0.09, 0.1), // window
  ]),
  ColouringPage('fish', [
    (s) => _poly(s, [(0.14, 0.28), (0.3, 0.5), (0.14, 0.72)]), // tail
    (s) => _oval(s, 0.24, 0.22, 0.56, 0.56), // body
    (s) => _poly(s, [(0.42, 0.25), (0.55, 0.08), (0.62, 0.25)]), // fin
    (s) => _oval(s, 0.64, 0.36, 0.08, 0.1), // eye
    (s) => _oval(s, 0.4, 0.44, 0.14, 0.14), // spot
  ]),
  ColouringPage('flower', [
    (s) => _box(s, 0.475, 0.5, 0.05, 0.44), // stem
    (s) => _oval(s, 0.3, 0.66, 0.18, 0.1), // leaf
    (s) => _oval(s, 0.52, 0.6, 0.18, 0.1), // leaf
    for (var i = 0; i < 6; i++)
      (s) {
        final a = i * math.pi / 3;
        return _oval(
          s,
          0.5 + math.cos(a) * 0.12 - 0.08,
          0.3 + math.sin(a) * 0.16 - 0.1,
          0.16,
          0.2,
        );
      },
    (s) => _oval(s, 0.42, 0.2, 0.16, 0.2), // centre
  ]),
  ColouringPage('car', [
    (s) => _box(s, 0.12, 0.42, 0.76, 0.26, 0.06), // body
    (s) => _box(s, 0.28, 0.2, 0.42, 0.26, 0.06), // top
    (s) => _box(s, 0.32, 0.25, 0.15, 0.16), // window
    (s) => _box(s, 0.51, 0.25, 0.15, 0.16), // window
    (s) => _oval(s, 0.2, 0.58, 0.18, 0.24), // wheel
    (s) => _oval(s, 0.62, 0.58, 0.18, 0.24), // wheel
  ]),
  ColouringPage('butterfly', [
    (s) => _oval(s, 0.18, 0.12, 0.3, 0.4), // wing
    (s) => _oval(s, 0.52, 0.12, 0.3, 0.4), // wing
    (s) => _oval(s, 0.24, 0.5, 0.24, 0.3), // wing
    (s) => _oval(s, 0.52, 0.5, 0.24, 0.3), // wing
    (s) => _box(s, 0.465, 0.2, 0.07, 0.62, 0.035), // body
  ]),
  ColouringPage('ice_cream', [
    (s) => _poly(s, [(0.34, 0.5), (0.66, 0.5), (0.5, 0.95)]), // cone
    (s) => _oval(s, 0.3, 0.3, 0.4, 0.3), // scoop
    (s) => _oval(s, 0.36, 0.1, 0.28, 0.26), // scoop
    (s) => _oval(s, 0.46, 0.02, 0.08, 0.1), // cherry
  ]),
];

/// The colours, with the colour words that teach their names.
const colouringColours = [
  ('colour_red', AppColors.paintRed),
  ('colour_yellow', AppColors.paintYellow),
  ('colour_blue', AppColors.paintBlue),
  ('colour_green', AppColors.paintGreen),
  ('colour_orange', AppColors.paintOrange),
  ('colour_pink', AppColors.paintPink),
  ('colour_purple', AppColors.paintPurple),
  ('colour_brown', AppColors.paintBrown),
];

@immutable
class ColouringState {
  const ColouringState({
    this.page = 0,
    this.colour = 0,
    this.fills = const {},
    this.done = 0,
  });

  final int page;

  /// Index into [colouringColours].
  final int colour;

  /// Area index → colour.
  final Map<int, Color> fills;

  /// Increments when a page is fully coloured (celebration).
  final int done;

  Color get current => colouringColours[colour].$2;

  bool get complete => fills.length == colouringPages[page].areas.length;

  ColouringState copyWith({
    int? page,
    int? colour,
    Map<int, Color>? fills,
    int? done,
  }) => ColouringState(
    page: page ?? this.page,
    colour: colour ?? this.colour,
    fills: fills ?? this.fills,
    done: done ?? this.done,
  );
}

/// Tap an area to fill it; the colour button picks the next colour and
/// says its name. A fully coloured page is celebrated.
class ColouringController extends Notifier<ColouringState> {
  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  ColouringState build() {
    final audio = _audio;
    ref.onDispose(() => unawaited(audio.stopVoice(owner: this)));
    return const ColouringState();
  }

  void fill(int area) {
    final areas = colouringPages[state.page].areas.length;
    if (area < 0 || area >= areas) return;
    final wasComplete = state.complete;
    ref.read(hapticsProvider).tap();
    _audio.playSfx(Sfx.pop);
    state = state.copyWith(fills: {...state.fills, area: state.current});
    if (!wasComplete && state.complete) {
      _audio.playSfx(Sfx.cheer);
      state = state.copyWith(done: state.done + 1);
      unawaited(
        ref
            .read(dailyPathProvider.notifier)
            .completed(PathStep(PathKind.toy, ToyKind.colouring.name)),
      );
    }
  }

  /// The next colour, and its name ("Blue!").
  Future<void> nextColour() async {
    final next = (state.colour + 1) % colouringColours.length;
    state = state.copyWith(colour: next);
    _audio.playSfx(Sfx.tap);
    final word = _colourWord(colouringColours[next].$1);
    if (word == null) return;
    final lang = ref.read(settingsProvider).language.languages.first;
    await _audio.playVoiceSequence(
      [word.voice(lang)],
      debounce: false,
      owner: this,
    );
  }

  void nextPage() {
    state = ColouringState(
      page: (state.page + 1) % colouringPages.length,
      colour: state.colour,
      done: state.done,
    );
    _audio.playSfx(Sfx.whoosh);
  }

  LearningItem? _colourWord(String id) => ref
      .read(contentCatalogProvider)
      .value
      ?.itemsFor(SectionId.colours)
      .where((i) => i.id == id)
      .firstOrNull;
}

final colouringControllerProvider =
    NotifierProvider.autoDispose<ColouringController, ColouringState>(
      ColouringController.new,
    );
