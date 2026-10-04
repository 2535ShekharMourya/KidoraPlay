import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/models/section.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/section_theme.dart';

/// Soft, slowly moving background for a section (or Home when [section] is
/// null): drifting clouds for Numbers and Home, a turning sun for ABC,
/// falling leaves for Animals, and a sunset sky for Birds.
///
/// Repaints only the painter (no rebuilds) and is static when the device
/// asks for reduced motion.
class SectionBackground extends StatefulWidget {
  const SectionBackground({required this.child, this.section, super.key});

  final SectionId? section;
  final Widget child;

  @override
  State<SectionBackground> createState() => _SectionBackgroundState();
}

class _SectionBackgroundState extends State<SectionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppDurations.backgroundLoop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _BackgroundPainter(widget.section, _loop),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.section, this.loop) : super(repaint: loop);

  final SectionId? section;
  final Animation<double> loop;

  @override
  void paint(Canvas canvas, Size size) {
    final t = loop.value;
    final rect = Offset.zero & size;
    final (top, bottom) = switch (section) {
      null => (AppColors.homeSky, AppColors.cream),
      SectionId.birds => (AppColors.sunsetTop, AppColors.birdsBg),
      final id => (SectionTheme.of(id).background, AppColors.cream),
    };
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );

    switch (section) {
      case null:
      case SectionId.numbers:
        _clouds(canvas, size, t);
      case SectionId.abc || SectionId.colours || SectionId.shapes:
        _sun(canvas, size, t, Offset(size.width * 0.9, size.height * 0.12));
        _bubbles(canvas, size, t);
      case SectionId.animals || SectionId.vegetables:
        _hills(canvas, size);
        _leaves(canvas, size, t);
      case SectionId.fruits:
        _sun(canvas, size, t, Offset(size.width * 0.88, size.height * 0.14));
        _clouds(canvas, size, t);
      case SectionId.birds:
        _sun(canvas, size, t, Offset(size.width * 0.82, size.height * 0.78));
        _clouds(canvas, size, t);
    }
  }

  void _clouds(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = AppColors.cloud.withValues(alpha: 0.85);
    const clouds = [
      (y: 0.12, scale: 1.0, speed: 1.0, offset: 0.0),
      (y: 0.30, scale: 0.7, speed: 0.6, offset: 0.45),
      (y: 0.08, scale: 0.55, speed: 1.4, offset: 0.7),
    ];
    for (final c in clouds) {
      final w = size.height * 0.45 * c.scale;
      final span = size.width + w * 2;
      final x = ((t * c.speed + c.offset) % 1) * span - w;
      final y = size.height * c.y;
      final r = w / 4;
      canvas
        ..drawCircle(Offset(x, y + r * 0.4), r, paint)
        ..drawCircle(Offset(x + r * 1.3, y), r * 1.35, paint)
        ..drawCircle(Offset(x + r * 2.7, y + r * 0.3), r * 1.05, paint)
        ..drawRRect(
          RRect.fromLTRBR(
            x - r * 0.2,
            y + r * 0.2,
            x + r * 3.6,
            y + r * 1.4,
            Radius.circular(r),
          ),
          paint,
        );
    }
  }

  void _sun(Canvas canvas, Size size, double t, Offset center) {
    final radius = size.shortestSide * 0.09;
    final rays = Paint()
      ..color = AppColors.sunRay
      ..strokeWidth = radius * 0.35
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = t * 2 * math.pi + i * math.pi / 6;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * radius * 1.4,
        center + dir * radius * 2.2,
        rays,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = AppColors.sun);
  }

  void _bubbles(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = AppColors.bubble;
    for (var i = 0; i < 9; i++) {
      final seed = i * 0.137;
      final x = size.width * ((seed * 7.3) % 1);
      final progress = (t * (0.8 + (i % 3) * 0.3) + seed) % 1;
      final y = size.height * (1.1 - progress * 1.2);
      final wobble = math.sin((progress * 4 + seed) * math.pi) * 12;
      canvas.drawCircle(
        Offset(x + wobble, y),
        size.shortestSide * (0.02 + (i % 4) * 0.008),
        paint,
      );
    }
  }

  void _hills(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.82)
          ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.55, h * 0.84)
          ..quadraticBezierTo(w * 0.8, h * 0.95, w, h * 0.8)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = AppColors.hillLight,
      )
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.92)
          ..quadraticBezierTo(w * 0.4, h * 0.84, w, h * 0.94)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = AppColors.hillDark,
      );
  }

  void _leaves(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 8; i++) {
      final seed = i * 0.173;
      final progress = (t * (1 + (i % 3) * 0.4) + seed) % 1;
      final x =
          size.width * ((seed * 5.1) % 1) +
          math.sin(progress * 3 * math.pi) * 30;
      final y = size.height * (progress * 1.2 - 0.1);
      final leaf = size.shortestSide * 0.035;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(math.sin(progress * 4 * math.pi) * 0.8)
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: leaf * 2, height: leaf),
          Paint()..color = i.isEven ? AppColors.leaf : AppColors.leafLight,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.section != section;
}
