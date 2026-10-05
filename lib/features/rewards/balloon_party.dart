import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/particle_burst.dart';

/// Counts cards completed this session; every [every]th one earns a
/// balloon party. Not saved: a predictable in-session reward, never a
/// reason to come back (no streaks, no random prizes).
class SessionRewards {
  static const every = 3;
  int _cards = 0;

  /// Records a completed card; true when it earns a party.
  bool cardCompleted() => ++_cards % every == 0;
}

final sessionRewardsProvider = Provider<SessionRewards>(
  (ref) => SessionRewards(),
);

/// "Balloon party!": balloons carrying just-learned pictures float up;
/// each tap pops one (pop, confetti, and its name). Ends when all are
/// popped or after [AppDurations.balloonParty]; then [onDone].
class BalloonParty extends ConsumerStatefulWidget {
  const BalloonParty({
    required this.items,
    required this.onDone,
    this.random,
    super.key,
  });

  final List<LearningItem> items;
  final VoidCallback onDone;
  final math.Random? random;

  @override
  ConsumerState<BalloonParty> createState() => _BalloonPartyState();
}

class _Balloon {
  _Balloon(this.item, this.x, this.delay, this.color);

  final LearningItem item;

  /// Horizontal position (0–1) and start delay (0–1 of the rise).
  final double x;
  final double delay;
  final Color color;
  bool popped = false;
}

class _BalloonPartyState extends ConsumerState<BalloonParty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: AppDurations.balloonRise,
  );
  final _burst = BurstController();
  Offset _burstAt = Offset.zero;
  late final List<_Balloon> _balloons;
  Timer? _end;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? math.Random();
    final items = [...widget.items]..shuffle(random);
    final shown = items.take(AppParticles.balloons).toList();
    _balloons = [
      for (final (i, item) in shown.indexed)
        _Balloon(
          item,
          (i + 0.5) / shown.length + (random.nextDouble() - 0.5) * 0.06,
          random.nextDouble() * 0.35,
          AppColors.confetti[i % AppColors.confetti.length],
        ),
    ];
    _rise.repeat();
    _end = Timer(AppDurations.balloonParty, _finish);
  }

  @override
  void dispose() {
    _end?.cancel();
    _rise.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  void _pop(_Balloon b, Offset at) {
    if (b.popped) return;
    setState(() {
      b.popped = true;
      _burstAt = at;
    });
    _burst.fire();
    ref.read(audioServiceProvider).playSfx(Sfx.pop);
    ref.read(hapticsProvider).tap();
    final lang = ref.read(settingsProvider).language.languages.first;
    unawaited(ref.read(audioServiceProvider).playVoice(b.item.voice(lang)));
    if (_balloons.every((b) => b.popped)) {
      _end?.cancel();
      _end = Timer(AppDurations.balloonLastPop, _finish);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final balloon = math.max(
          AppSpacing.minTapTarget,
          math.min(size.width / (_balloons.length + 1), size.height * 0.34),
        );
        return Stack(
          children: [
            // Soft veil: the party is on top, the card waits behind.
            const Positioned.fill(
              child: ColoredBox(color: AppColors.partyVeil),
            ),
            AnimatedBuilder(
              animation: _rise,
              builder: (context, _) => Stack(
                children: [
                  for (final b in _balloons)
                    if (!b.popped) _positioned(b, size, balloon, reduceMotion),
                ],
              ),
            ),
            Positioned(
              left: _burstAt.dx,
              top: _burstAt.dy,
              child: IgnorePointer(
                child: ParticleBurst(
                  controller: _burst,
                  style: BurstStyle.confetti,
                  child: const SizedBox.square(dimension: 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _positioned(_Balloon b, Size size, double balloon, bool reduceMotion) {
    final height = balloon * 1.45;
    // Rise from below the screen to above it, then come round again.
    final t = reduceMotion ? 0.5 : (_rise.value + 1 - b.delay) % 1;
    final y = size.height - t * (size.height + height);
    final sway = reduceMotion ? 0.0 : math.sin(t * math.pi * 4) * 10;
    final left = (b.x * size.width - balloon / 2 + sway).clamp(
      0.0,
      size.width - balloon,
    );
    return Positioned(
      left: left,
      top: y,
      width: balloon,
      height: height,
      child: Semantics(
        button: true,
        label: b.item.wordEn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) =>
              _pop(b, Offset(left + balloon / 2, y + balloon / 2)),
          child: _BalloonView(item: b.item, color: b.color),
        ),
      ),
    );
  }
}

class _BalloonView extends StatelessWidget {
  const _BalloonView({required this.item, required this.color});

  final LearningItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return CustomPaint(
          painter: _StringPainter(color),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: w,
              height: w / 0.86,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(w / 2, w / 0.86 / 2),
                        ),
                        border: Border.all(
                          color: AppColors.outline,
                          width: AppStroke.thick,
                        ),
                      ),
                      // A coloured skin around the picture.
                      padding: EdgeInsets.all(w * 0.16),
                      child: ClipOval(
                        child: ColoredBox(
                          color: AppColors.white,
                          child: Image.asset(
                            item.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Shine.
                  Positioned(
                    left: w * 0.16,
                    top: w * 0.1,
                    width: w * 0.16,
                    height: w * 0.24,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.balloonShine,
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The balloon's knot and string, hanging below it.
class _StringPainter extends CustomPainter {
  _StringPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.width / 0.86;
    final cx = size.width / 2;
    final knot = size.width * 0.08;
    canvas.drawPath(
      Path()
        ..moveTo(cx - knot, top + knot)
        ..lineTo(cx + knot, top + knot)
        ..lineTo(cx, top - knot / 2)
        ..close(),
      Paint()..color = color,
    );
    final path = Path()..moveTo(cx, top + knot);
    path.quadraticBezierTo(
      size.width * 0.35,
      (top + size.height) / 2,
      cx,
      size.height,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.thin,
    );
  }

  @override
  bool shouldRepaint(_StringPainter old) => old.color != color;
}
