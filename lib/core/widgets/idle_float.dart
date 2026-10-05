import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Gentle up-and-down "breathing" so idle screens feel alive.
/// [phase] (0–1) offsets neighbours so they don't move in lockstep.
class IdleFloat extends StatefulWidget {
  const IdleFloat({required this.child, this.phase = 0, super.key});

  final Widget child;
  final double phase;

  @override
  State<IdleFloat> createState() => _IdleFloatState();
}

class _IdleFloatState extends State<IdleFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppDurations.idleFloat,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        // Same tree when stopped, so the child keeps its state.
        final t = (_anim.value + widget.phase) * 2 * math.pi;
        return Transform.translate(
          offset: _anim.isAnimating
              ? Offset(0, math.sin(t) * AppScale.idleFloatOffset)
              : Offset.zero,
          child: child,
        );
      },
      // Moved, not repainted, every frame.
      child: RepaintBoundary(child: widget.child),
    );
  }
}
