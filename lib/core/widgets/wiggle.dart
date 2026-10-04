import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Shakes its child while [active], e.g. an animal reacting to its own
/// sound. Still under reduced motion.
class Wiggle extends StatefulWidget {
  const Wiggle({required this.active, required this.child, super.key});

  final bool active;
  final Widget child;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppDurations.wiggle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Wiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_anim.isAnimating) {
      _anim.repeat(reverse: true);
    } else if (!run && _anim.isAnimating) {
      _anim
        ..stop()
        ..value = 0.5;
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
        if (!_anim.isAnimating) return child!;
        final t = (_anim.value - 0.5) * 2; // -1..1
        return Transform.rotate(
          angle: t * 0.07,
          child: Transform.scale(scale: 1 + 0.04 * (1 - t.abs()), child: child),
        );
      },
      child: widget.child,
    );
  }
}
