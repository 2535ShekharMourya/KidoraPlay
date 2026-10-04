import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'kido_controller.dart';

/// Placeholder Kido drawn in code: a baby elephant facing right.
///
/// Stands in for `assets/rive/kido.riv` until the Rive art exists. All
/// inputs are 0–1 animation values, so this stays a pure function of its
/// parameters and is cheap to repaint.
class KidoPainter extends CustomPainter {
  KidoPainter({
    required this.action,
    required this.idle,
    required this.progress,
    required this.talk,
    required this.talking,
    required this.target,
    required this.reduceMotion,
    super.repaint,
  });

  final KidoAction action;
  final Animation<double> idle;
  final Animation<double> progress;
  final Animation<double> talk;
  final bool talking;

  /// Local point Kido looks/points at, if any.
  final Offset? Function() target;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final p = progress.value;
    final t = reduceMotion ? 0.0 : idle.value;

    // Whole-body motion: gentle breathing, hops for happy moments.
    var lift = math.sin(t * 2 * math.pi) * 0.015 * h;
    if (!reduceMotion) {
      lift -= switch (action) {
        KidoAction.clap => (math.sin(p * 2 * math.pi).abs()) * 0.10 * h,
        KidoAction.surprised || KidoAction.trumpet =>
          math.sin(p * math.pi) * 0.12 * h,
        _ => 0,
      };
    }

    final trunkBase = Offset(w * 0.80, h * 0.43 + lift);
    final aim = _aimAngle(trunkBase);

    // Shadow stays on the ground.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.96),
        width: h * 0.7,
        height: h * 0.07,
      ),
      Paint()..color = AppColors.kidoShadow,
    );

    canvas
      ..save()
      ..translate(0, lift);
    _body(canvas, w, h);
    canvas.restore();

    // Head group pivots at the neck: thinking tilts, looking leans.
    final neck = Offset(w * 0.55, h * 0.55 + lift);
    final tilt = switch (action) {
      KidoAction.think => -0.14,
      KidoAction.look || KidoAction.point =>
        aim == null ? 0.0 : (aim.clamp(-0.6, 0.6)) * 0.25,
      _ => 0.0,
    };
    canvas
      ..save()
      ..translate(neck.dx, neck.dy)
      ..rotate(tilt)
      ..translate(-neck.dx, -neck.dy)
      ..translate(0, lift);
    _ear(canvas, w, h, p, t);
    _head(canvas, w, h, p, aim);
    _trunk(canvas, Offset(w * 0.80, h * 0.43), h, p, aim);
    canvas.restore();

    if (action == KidoAction.think) _thinkDots(canvas, w, h, t);
  }

  double? _aimAngle(Offset from) {
    final to = target();
    if (to == null) return null;
    final d = to - from;
    // Facing right: keep the trunk in front of him.
    return math.atan2(d.dy, d.dx).clamp(-1.7, 1.7);
  }

  void _body(Canvas canvas, double w, double h) {
    final grey = Paint()..color = AppColors.kidoGrey;
    final dark = Paint()..color = AppColors.kidoGreyDark;
    for (final x in [0.28, 0.52]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * 0.74, h * 0.13, h * 0.2),
          Radius.circular(h * 0.05),
        ),
        dark,
      );
    }
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.44, h * 0.68),
          width: h * 0.66,
          height: h * 0.46,
        ),
        grey,
      )
      ..drawLine(
        Offset(w * 0.17, h * 0.64),
        Offset(w * 0.10, h * 0.74),
        Paint()
          ..color = AppColors.kidoGreyDark
          ..strokeWidth = h * 0.03
          ..strokeCap = StrokeCap.round,
      );
  }

  void _ear(Canvas canvas, double w, double h, double p, double t) {
    final flap = switch (action) {
      KidoAction.wave => math.sin(p * 6 * math.pi) * 0.4,
      KidoAction.coverEars => 0.55,
      _ when talking => (talk.value - 0.5) * 0.3,
      _ => math.sin(t * 2 * math.pi) * 0.05,
    };
    final center = Offset(w * 0.47, h * 0.40);
    canvas
      ..save()
      ..translate(center.dx + h * 0.1, center.dy - h * 0.1)
      ..rotate(flap)
      ..translate(-(center.dx + h * 0.1), -(center.dy - h * 0.1))
      ..drawOval(
        Rect.fromCenter(center: center, width: h * 0.36, height: h * 0.44),
        Paint()..color = AppColors.kidoGrey,
      )
      ..drawOval(
        Rect.fromCenter(
          center: center + Offset(h * 0.01, h * 0.01),
          width: h * 0.24,
          height: h * 0.32,
        ),
        Paint()..color = AppColors.kidoPink,
      )
      ..restore();
  }

  void _head(Canvas canvas, double w, double h, double p, double? aim) {
    canvas.drawCircle(
      Offset(w * 0.64, h * 0.40),
      h * 0.25,
      Paint()..color = AppColors.kidoGrey,
    );

    // Eye follows the target.
    final surprised = action == KidoAction.surprised;
    final eye = Offset(w * 0.71, h * 0.33);
    final look = aim == null
        ? Offset.zero
        : Offset(math.cos(aim), math.sin(aim)) * h * 0.012;
    final r = h * (surprised ? 0.055 : 0.04);
    canvas
      ..drawCircle(eye + look, r, Paint()..color = AppColors.kidoEye)
      ..drawCircle(
        eye + look + Offset(-r * 0.3, -r * 0.35),
        r * 0.35,
        Paint()..color = AppColors.white,
      )
      ..drawCircle(
        Offset(w * 0.75, h * 0.46),
        h * 0.035,
        Paint()..color = AppColors.kidoPink.withValues(alpha: 0.8),
      );

    // Mouth: smile, open while talking, "o" when surprised.
    final mouth = Offset(w * 0.70, h * 0.53);
    final ink = Paint()..color = AppColors.kidoEye;
    if (talking || surprised) {
      final open = surprised ? 1.0 : talk.value;
      canvas.drawOval(
        Rect.fromCenter(
          center: mouth,
          width: h * 0.07,
          height: h * (0.02 + 0.05 * open),
        ),
        ink,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: mouth, width: h * 0.08, height: h * 0.05),
        0.2,
        math.pi - 0.4,
        false,
        ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.015
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _trunk(Canvas canvas, Offset base, double h, double p, double? aim) {
    // Each trunk pose is two segments: (angle, length) in units of h.
    final (a1, l1, a2, l2) = switch (action) {
      KidoAction.point || KidoAction.look when aim != null => (
          aim,
          action == KidoAction.point ? 0.2 : 0.14,
          aim - 0.25,
          action == KidoAction.point ? 0.14 : 0.08,
        ),
      KidoAction.spellTap => (
          (aim ?? 0.9),
          0.16 + 0.08 * math.sin(p * math.pi),
          (aim ?? 0.9) + 0.3,
          0.1,
        ),
      KidoAction.trumpet => (-1.2, 0.2, -1.9, 0.1),
      KidoAction.wave => (
          math.sin(p * 4 * math.pi) * 0.7 - 0.2,
          0.18,
          math.sin(p * 4 * math.pi) * 0.7 - 0.9,
          0.1,
        ),
      _ => (1.15, 0.18, 2.6, 0.08), // relaxed curl
    };
    final mid = base + Offset(math.cos(a1), math.sin(a1)) * h * l1;
    final tip = mid + Offset(math.cos(a2), math.sin(a2)) * h * l2;
    final trunk = Paint()
      ..color = AppColors.kidoGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy),
      trunk,
    );
  }

  void _thinkDots(Canvas canvas, double w, double h, double t) {
    final paint = Paint()..color = AppColors.white;
    for (var i = 0; i < 3; i++) {
      final pulse = 1 + 0.15 * math.sin((t * 2 + i / 3) * 2 * math.pi);
      canvas.drawCircle(
        Offset(w * (0.82 + i * 0.07), h * (0.12 - i * 0.04)),
        h * (0.025 + i * 0.012) * pulse,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(KidoPainter old) =>
      old.action != action ||
      old.talking != talking ||
      old.reduceMotion != reduceMotion;
}
