import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_service.dart';
import '../../core/theme/app_tokens.dart';
import 'kido_controller.dart';
import 'kido_painter.dart';

/// Kido, animated from [kidoControllerProvider]. Talks automatically while
/// any voice clip plays.
class KidoWidget extends ConsumerStatefulWidget {
  const KidoWidget({super.key});

  @override
  ConsumerState<KidoWidget> createState() => _KidoWidgetState();
}

class _KidoWidgetState extends ConsumerState<KidoWidget>
    with TickerProviderStateMixin {
  late final _idle = AnimationController(
    vsync: this,
    duration: AppDurations.kidoIdle,
  );
  late final _action = AnimationController(
    vsync: this,
    duration: AppDurations.kidoHold,
  );
  late final _talk = AnimationController(
    vsync: this,
    duration: AppDurations.kidoTalk,
  );
  late final ValueNotifier<bool> _speaking = ref
      .read(audioServiceProvider)
      .speaking;

  @override
  void initState() {
    super.initState();
    _speaking.addListener(_syncTalk);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  void _syncTalk() {
    if (!mounted) return;
    if (_speaking.value) {
      _talk.repeat(reverse: true);
    } else {
      _talk
        ..stop()
        ..value = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _speaking.removeListener(_syncTalk);
    _idle.dispose();
    _action.dispose();
    _talk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kidoControllerProvider);
    ref.listen(kidoControllerProvider.select((s) => s.seq), (_, _) {
      final action = ref.read(kidoControllerProvider).action;
      _action
        ..duration = action.oneShot ?? AppDurations.kidoHold
        ..forward(from: 0);
    });

    Offset? localTarget() {
      final target = state.target;
      final box = context.findRenderObject() as RenderBox?;
      if (target == null || box == null || !box.hasSize) return null;
      return box.globalToLocal(target);
    }

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: KidoPainter(
            action: state.action,
            idle: _idle,
            progress: _action,
            talk: _talk,
            talking: _speaking.value,
            target: localTarget,
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            repaint: Listenable.merge([_idle, _action, _talk]),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Places Kido bottom-left (about 20% of the screen height), inside the
/// left column that layouts keep free, so he never covers a tap target.
/// Use inside a [Stack]. Kido himself is not tappable.
class KidoCorner extends StatelessWidget {
  const KidoCorner({super.key});

  /// Kido's size for a screen of [screen] size.
  static Size sizeFor(Size screen) {
    const maxWidth = AppLayout.sideZone - AppSpacing.md;
    final height = math.min(
      screen.height * AppLayout.kidoHeightFraction,
      maxWidth / AppLayout.kidoAspect,
    );
    return Size(height * AppLayout.kidoAspect, height);
  }

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(MediaQuery.sizeOf(context));
    return Positioned(
      left: AppSpacing.sm,
      bottom: AppSpacing.sm,
      width: size.width,
      height: size.height,
      child: const IgnorePointer(child: KidoWidget()),
    );
  }
}
