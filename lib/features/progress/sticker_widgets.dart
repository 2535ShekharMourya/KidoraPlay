import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';

/// The sticker jar: a round badge with a star and a count. Bounces when
/// [count] goes up. Stickers fly into it.
class StickerJar extends StatelessWidget {
  const StickerJar({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: reduceMotion ? 1 : 1.3, end: 1),
      duration: reduceMotion ? Duration.zero : AppDurations.popIn,
      curve: AppCurves.popIn,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: AppSpacing.minTapTarget,
        height: AppSpacing.minTapTarget,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_rounded,
              color: AppColors.celebrate,
              size: AppSpacing.minTapTarget * 0.45,
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flies a sticker picture from [from] to [to] (global rects) along an arc,
/// shrinking as it goes, then calls [onArrive]. Skipped under reduced
/// motion.
void flySticker(
  BuildContext context, {
  required String image,
  required Rect from,
  required Rect to,
  VoidCallback? onArrive,
}) {
  if (MediaQuery.disableAnimationsOf(context)) {
    onArrive?.call();
    return;
  }
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.stickerFlight,
        curve: Curves.easeInOutCubic,
        onEnd: () {
          entry.remove();
          onArrive?.call();
        },
        builder: (context, t, child) {
          // Quadratic Bézier with the control point above both ends.
          final control = Offset(
            (from.center.dx + to.center.dx) / 2,
            math.min(from.top, to.top) - from.height * 0.6,
          );
          final a = Offset.lerp(from.center, control, t)!;
          final b = Offset.lerp(control, to.center, t)!;
          final center = Offset.lerp(a, b, t)!;
          final size = from.width + (to.width * 0.8 - from.width) * t;
          return Positioned(
            left: center.dx - size / 2,
            top: center.dy - size / 2,
            width: size,
            height: size,
            child: Transform.rotate(
              angle: math.sin(t * math.pi) * 0.3,
              child: child,
            ),
          );
        },
        child: Image.asset(image, fit: BoxFit.contain),
      ),
    ),
  );
  overlay.insert(entry);
}

/// Full-screen celebration for finishing a set: confetti and a big star
/// with the set's picture. Never blocks taps; fades out on its own.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({required this.image, super.key});

  /// Section or item picture shown in the middle.
  final String image;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  final _confetti = BurstController();
  bool _visible = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.fire());
    _hide = Timer(AppDurations.celebration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: AppDurations.pageTransition,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ParticleBurst(controller: _confetti, style: BurstStyle.confetti),
            Center(
              child: PopIn(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: MediaQuery.sizeOf(context).shortestSide * 0.85,
                      color: AppColors.celebrate,
                      shadows: const [
                        Shadow(color: AppColors.glow, blurRadius: 40),
                      ],
                    ),
                    SizedBox.square(
                      dimension: MediaQuery.sizeOf(context).shortestSide * 0.32,
                      child: Image.asset(widget.image, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
