import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Fires a [ParticleBurst]. Call [fire] from tap handlers or completion
/// events.
class BurstController extends ChangeNotifier {
  void fire() => notifyListeners();
}

enum BurstStyle {
  /// Small star sparkle around a tapped item.
  sparkle,

  /// Full-screen confetti shower for completions.
  confetti,
}

/// Stars/confetti that never block taps. Paints outside its own bounds, so
/// wrap the tapped widget with it (sparkle) or fill the screen (confetti).
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    required this.controller,
    this.style = BurstStyle.sparkle,
    this.child,
    this.random,
    super.key,
  });

  final BurstController controller;
  final BurstStyle style;
  final Widget? child;

  /// Injectable for deterministic tests.
  final math.Random? random;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: _duration,
  );
  late final math.Random _random = widget.random ?? math.Random();
  List<_Particle> _particles = const [];

  Duration get _duration => switch (widget.style) {
        BurstStyle.sparkle => AppDurations.sparkle,
        BurstStyle.confetti => AppDurations.confetti,
      };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_fire);
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _particles = const []);
      }
    });
  }

  @override
  void didUpdateWidget(ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_fire);
      widget.controller.addListener(_fire);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fire);
    _anim.dispose();
    super.dispose();
  }

  void _fire() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _particles = _spawn());
    _anim.forward(from: 0);
  }

  List<_Particle> _spawn() {
    const colors = AppColors.confetti;
    switch (widget.style) {
      case BurstStyle.sparkle:
        return List.generate(AppParticles.sparkle, (i) {
          final angle = (i / AppParticles.sparkle) * 2 * math.pi +
              _random.nextDouble() * 0.4;
          return _Particle(
            angle: angle,
            speed: 0.7 + _random.nextDouble() * 0.5,
            size: 8 + _random.nextDouble() * 8,
            color: colors[i % colors.length],
            shape: _Shape.star,
            spin: (_random.nextDouble() - 0.5) * 6,
          );
        });
      case BurstStyle.confetti:
        return List.generate(AppParticles.confetti, (i) {
          return _Particle(
            // Mostly upward fan from the bottom centre.
            angle: -math.pi / 2 + (_random.nextDouble() - 0.5) * 1.6,
            speed: 0.8 + _random.nextDouble() * 0.6,
            size: 8 + _random.nextDouble() * 10,
            color: colors[_random.nextInt(colors.length)],
            shape: _Shape.values[_random.nextInt(_Shape.values.length)],
            spin: (_random.nextDouble() - 0.5) * 12,
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        if (widget.child != null) widget.child!,
        if (widget.child == null) const SizedBox.expand(),
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BurstPainter(
                  particles: _particles,
                  progress: _anim,
                  style: widget.style,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _Shape { star, circle, rect }

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.shape,
    required this.spin,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final _Shape shape;
  final double spin;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.particles,
    required this.progress,
    required this.style,
  }) : super(repaint: progress);

  final List<_Particle> particles;
  final Animation<double> progress;
  final BurstStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint();
    final sparkle = style == BurstStyle.sparkle;
    final origin = sparkle
        ? size.center(Offset.zero)
        : Offset(size.width / 2, size.height);
    // Distance scale: sparkle stays near the item, confetti fills the screen.
    final reach = sparkle
        ? size.shortestSide * 0.9
        : size.height * 1.3;
    final gravity = sparkle ? reach * 0.4 : reach * 1.1;
    final eased = Curves.easeOutCubic.transform(t);
    final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * reach * eased;
      final dy = math.sin(p.angle) * p.speed * reach * eased + gravity * t * t;
      final scale = sparkle ? (1 - t * 0.5) : 1.0;
      paint.color = p.color.withValues(alpha: opacity.clamp(0, 1));

      canvas
        ..save()
        ..translate(origin.dx + dx, origin.dy + dy)
        ..rotate(p.spin * t);
      final s = p.size * scale;
      switch (p.shape) {
        case _Shape.star:
          canvas.drawPath(_star(s), paint);
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, s / 2, paint);
        case _Shape.rect:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.5),
            paint,
          );
      }
      canvas.restore();
    }
  }

  static Path _star(double size) {
    final path = Path();
    final outer = size / 2;
    final inner = outer * 0.45;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.particles != particles || old.style != style;
}
