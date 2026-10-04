import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Makes a tap target call for attention: a soft pulsing glow, plus a
/// bounce when [strong] (the last hint level). Static glow under reduced
/// motion.
class Beckon extends StatefulWidget {
  const Beckon({
    required this.active,
    required this.child,
    this.strong = false,
    this.radius = AppRadii.card,
    super.key,
  });

  final bool active;
  final bool strong;
  final double radius;
  final Widget child;

  @override
  State<Beckon> createState() => _BeckonState();
}

class _BeckonState extends State<Beckon> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.beckon,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Beckon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!run) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Same widget structure whether active or not, so the child keeps its
    // state when the glow switches on and off.
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        if (!widget.active) {
          return Transform.scale(
            scale: 1,
            child: DecoratedBox(
              decoration: const BoxDecoration(),
              child: child,
            ),
          );
        }
        final v = Curves.easeInOut.transform(_pulse.value);
        final bounce = widget.strong ? math.sin(v * math.pi) * 0.1 : 0.0;
        return Transform.scale(
          scale: 1 + bounce,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glow,
                  blurRadius: 18 + 14 * v,
                  spreadRadius: 2 + 6 * v,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
