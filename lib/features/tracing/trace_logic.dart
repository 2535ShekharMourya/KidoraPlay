import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';

/// One stroke: evenly spaced points in a unit box (x right, y down), in the
/// direction the finger moves.
typedef Stroke = List<Offset>;

/// How to write each glyph (A–Z, 0–9), from `assets/content/tracing.json`
/// (made by `tool/make_tracing.py`).
@immutable
class TraceGuides {
  const TraceGuides(this._glyphs);

  factory TraceGuides.fromJson(Map<String, Object?> json) => TraceGuides({
    for (final MapEntry(:key, :value) in json.entries)
      key: [
        for (final stroke in value! as List)
          resample([
            for (final p in stroke as List)
              Offset(
                ((p as List)[0] as num).toDouble(),
                (p[1] as num).toDouble(),
              ),
          ]),
      ],
  });

  final Map<String, List<Stroke>> _glyphs;

  List<Stroke>? strokesOf(String glyph) => _glyphs[glyph];

  /// The glyphs to write for [item] ("A", or "2", "1" for 21), or null when
  /// it can't be traced.
  List<String>? glyphsFor(LearningItem item) {
    final text = switch (item.section) {
      SectionId.abc => item.letter?.toUpperCase(),
      SectionId.numbers => item.number?.toString(),
      _ => null,
    };
    if (text == null || text.isEmpty) return null;
    final glyphs = text.split('');
    return glyphs.every(_glyphs.containsKey) ? glyphs : null;
  }
}

/// Spacing between resampled points, in the unit box.
const traceStep = 0.02;

/// Points every [step] along [points], so progress moves smoothly.
Stroke resample(List<Offset> points, {double step = traceStep}) {
  if (points.length < 2) return List.unmodifiable(points);
  final out = <Offset>[points.first];
  var carry = 0.0;
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final len = (b - a).distance;
    var d = step - carry;
    while (d <= len) {
      out.add(Offset.lerp(a, b, d / len)!);
      d += step;
    }
    carry = len - (d - step);
  }
  if ((out.last - points.last).distance > step * 0.3) out.add(points.last);
  return List.unmodifiable(out);
}

Future<TraceGuides> loadTraceGuides(AssetBundle bundle) async {
  final raw = await bundle.loadString('assets/content/tracing.json');
  return TraceGuides.fromJson(jsonDecode(raw) as Map<String, Object?>);
}

final traceGuidesProvider = FutureProvider<TraceGuides>(
  (ref) => loadTraceGuides(rootBundle),
);

/// What a finger movement achieved.
enum TraceStep { none, progress, strokeDone, glyphDone, allDone }

/// Where the child is in writing a word: which glyph, which stroke, and how
/// far along it.
@immutable
class TracePosition {
  const TracePosition({this.glyph = 0, this.stroke = 0, this.progress = 0});

  final int glyph;
  final int stroke;

  /// Index of the furthest point reached on the current stroke.
  final int progress;

  @override
  bool operator ==(Object other) =>
      other is TracePosition &&
      other.glyph == glyph &&
      other.stroke == stroke &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(glyph, stroke, progress);
}

/// Forgiving tracing rules for small fingers: the finger pulls the stroke
/// along when it is near the next stretch of the path. Wandering off does
/// nothing (no "wrong"), lifting the finger keeps the progress.
abstract final class TraceRules {
  /// How close the finger must be to the path (unit box).
  static const tolerance = 0.12;

  /// How far ahead along the path one move can jump (points).
  static const lookAhead = 10;

  static (TracePosition, TraceStep) move(
    List<List<Stroke>> glyphs,
    TracePosition at,
    int glyph,
    Offset finger,
  ) {
    if (at.glyph >= glyphs.length || glyph != at.glyph) {
      return (at, TraceStep.none);
    }
    final stroke = glyphs[at.glyph][at.stroke];
    final last = math.min(stroke.length - 1, at.progress + lookAhead);
    var reached = -1;
    for (var i = at.progress; i <= last; i++) {
      if ((stroke[i] - finger).distance <= tolerance) reached = i;
    }
    if (reached <= at.progress) return (at, TraceStep.none);
    if (reached < stroke.length - 1) {
      return (
        TracePosition(glyph: at.glyph, stroke: at.stroke, progress: reached),
        TraceStep.progress,
      );
    }
    // Stroke finished: on to the next stroke, glyph, or done.
    if (at.stroke + 1 < glyphs[at.glyph].length) {
      return (
        TracePosition(glyph: at.glyph, stroke: at.stroke + 1),
        TraceStep.strokeDone,
      );
    }
    final next = TracePosition(glyph: at.glyph + 1);
    return (
      next,
      next.glyph >= glyphs.length ? TraceStep.allDone : TraceStep.glyphDone,
    );
  }
}
