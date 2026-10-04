import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../haptics/haptics.dart';
import '../theme/app_tokens.dart';
import 'particle_burst.dart';

/// The one tappable building block for child screens.
///
/// Every tap gets instant feedback: squash on press, spring bounce
/// (1.0 → 1.15 → 1.0) on release, a sound, a light haptic, and optionally a
/// sparkle.
/// Repeated taps within [AppDurations.tapDebounce] are ignored so toddler
/// mashing doesn't trigger the action again and again.
///
/// Only plain taps are recognised: no long-press, double-tap or drag.
class BouncyButton extends ConsumerStatefulWidget {
  const BouncyButton({
    required this.child,
    required this.semanticLabel,
    required this.onPressed,
    this.sparkle = true,
    this.sfx = Sfx.pop,
    this.minSize = AppSpacing.minTapTarget,
    super.key,
  });

  final Widget child;

  /// Read by TalkBack for parents/testers.
  final String semanticLabel;

  /// Null disables the button (no feedback at all).
  final VoidCallback? onPressed;
  final bool sparkle;

  /// Tap sound; null when the tap plays a voice clip instead.
  final Sfx? sfx;
  final double minSize;

  @override
  ConsumerState<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends ConsumerState<BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: AppDurations.tapBounce,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: AppScale.pressed,
        end: AppScale.tapPeak,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: AppScale.tapPeak,
        end: 1.0,
      ).chain(CurveTween(curve: AppCurves.tapSettle)),
      weight: 70,
    ),
  ]).animate(_bounce);

  final _burst = BurstController();
  Timer? _cooldown;
  bool _pressed = false;

  @override
  void dispose() {
    _cooldown?.cancel();
    _bounce.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _handleTap() {
    _setPressed(false);
    if (_cooldown?.isActive ?? false) return;
    _cooldown = Timer(AppDurations.tapDebounce, () {});

    if (widget.sfx case final sfx?) {
      ref.read(audioServiceProvider).playSfx(sfx);
    }
    ref.read(hapticsProvider).tap();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _bounce.forward(from: 0);
      if (widget.sparkle) _burst.fire();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minSize,
        minHeight: widget.minSize,
      ),
      child: widget.child,
    );

    content = AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final scale = _bounce.isAnimating
            ? _scale.value
            : (_pressed ? AppScale.pressed : 1.0);
        return Transform.scale(scale: scale, child: child);
      },
      child: content,
    );

    if (widget.sparkle) {
      content = ParticleBurst(controller: _burst, child: content);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: enabled ? _handleTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? _handleTap : null,
        child: content,
      ),
    );
  }
}
