import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Entry animation: the child springs in after `index × stagger`.
class PopIn extends StatefulWidget {
  const PopIn({required this.child, this.index = 0, super.key});

  final Widget child;

  /// Position in the group; drives the stagger delay.
  final int index;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppDurations.popIn,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _anim,
    curve: AppCurves.popIn,
  );
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_anim.isDismissed && _delay == null) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _anim.value = 1;
      } else {
        _delay = Timer(AppDurations.staggerStep * widget.index, () {
          if (mounted) _anim.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value.clamp(0, 1),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
