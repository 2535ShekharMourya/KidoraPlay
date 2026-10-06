import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/learning_item.dart';
import '../../core/audio/audio_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_manager.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_widget.dart';
import '../section_grid/section_items.dart';
import 'trace_controller.dart';
import 'trace_logic.dart';

/// Finger tracing for a letter or number: the child drags along the
/// glyph's strokes from the green dot, Kido shows how and cheers. The only
/// child screen that uses drag.
class TraceScreen extends ConsumerStatefulWidget {
  const TraceScreen({required this.scope, required this.itemId, super.key});

  final ItemScope scope;
  final String itemId;

  @override
  ConsumerState<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends ConsumerState<TraceScreen> {
  final _sparkle = BurstController();
  final _confetti = BurstController();
  final _boardKey = GlobalKey();
  bool _started = false;
  Timer? _adBreak;

  TraceController get _controller =>
      ref.read(traceControllerProvider(widget.itemId).notifier);
  KidoController get _kido => ref.read(kidoControllerProvider.notifier);

  @override
  void dispose() {
    _adBreak?.cancel();
    _sparkle.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _maybeStart(LearningItem item, TraceGuides guides) {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start(item, guides);
    });
  }

  Offset? _boardCenter() {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _directKido(TraceState? prev, TraceState next) {
    if (next.celebrations > (prev?.celebrations ?? 0)) {
      _confetti.fire();
      _kido.act(KidoAction.trumpet);
      // A finished letter is a natural break: maybe an ad after the cheer.
      _adBreak?.cancel();
      _adBreak = Timer(AppDurations.celebration, () {
        if (!mounted) return;
        unawaited(
          ref
              .read(adManagerProvider)
              .maybeShowBreak(context, reason: 'trace_done'),
        );
      });
    } else if (next.strokesDone > (prev?.strokesDone ?? 0)) {
      _sparkle.fire();
      _kido.act(KidoAction.clap);
    } else if (next.demo != prev?.demo) {
      _kido.act(KidoAction.point, target: _boardCenter());
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(scopeItemsProvider(widget.scope));
    final index = items.indexWhere((i) => i.id == widget.itemId);
    final guides = ref.watch(traceGuidesProvider).value;
    final theme = SectionTheme.of(widget.scope.section);
    final item = index < 0 ? null : items[index];
    final glyphs = item == null ? null : guides?.glyphsFor(item);
    if (item != null && glyphs != null) _maybeStart(item, guides!);

    ref.listen(traceControllerProvider(widget.itemId), _directKido);
    final state = ref.watch(traceControllerProvider(widget.itemId));
    final l10n = AppLocalizations.of(context);

    LearningItem? nextItem;
    for (final other in items.skip(index + 1)) {
      if (guides?.glyphsFor(other) != null) {
        nextItem = other;
        break;
      }
    }

    return Scaffold(
      body: SectionBackground(
        section: widget.scope.section,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: !state.ready
                      ? const SizedBox.shrink()
                      : PopIn(
                          key: ValueKey(widget.itemId),
                          child: ParticleBurst(
                            controller: _sparkle,
                            child: TraceBoard(
                              key: _boardKey,
                              state: state,
                              accent: theme.accent,
                              onMove: _controller.move,
                            ),
                          ),
                        ),
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              if (state.finished) ...[
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: PopIn(
                      child: _RoundButton(
                        icon: Icons.replay_rounded,
                        label: l10n.traceAgain,
                        color: theme.accent,
                        onPressed: _controller.again,
                      ),
                    ),
                  ),
                ),
                if (nextItem case final next?)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: PopIn(
                        child: ArrowButton(
                          direction: ArrowDirection.next,
                          color: theme.accent,
                          onPressed: () => context.go(
                            AppRoutes.trace(widget.scope, next.id),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              const KidoCorner(),
              Positioned.fill(
                child: IgnorePointer(
                  child: ParticleBurst(
                    controller: _confetti,
                    style: BurstStyle.confetti,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button (write again).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      semanticLabel: label,
      sfx: Sfx.whoosh,
      onPressed: onPressed,
      child: Container(
        width: AppSpacing.minTapTarget,
        height: AppSpacing.minTapTarget,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        child: Icon(
          icon,
          size: AppSpacing.minTapTarget * 0.55,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// The writing board: one square per glyph, the road to trace, the ink,
/// the green start dot, arrows, and Kido's demo finger.
class TraceBoard extends StatefulWidget {
  const TraceBoard({
    required this.state,
    required this.accent,
    required this.onMove,
    super.key,
  });

  final TraceState state;
  final Color accent;

  /// The finger is at a unit-box point over glyph `glyph`.
  final void Function(int glyph, Offset point) onMove;

  @override
  State<TraceBoard> createState() => _TraceBoardState();
}

class _TraceBoardState extends State<TraceBoard> with TickerProviderStateMixin {
  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: AppDurations.traceDemo,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.beckon,
  );
  final _trail = <Offset>[];
  double _box = 1;

  @override
  void initState() {
    super.initState();
    _startDemo();
  }

  @override
  void didUpdateWidget(TraceBoard old) {
    super.didUpdateWidget(old);
    if (widget.state.demo != old.state.demo) _startDemo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  void _startDemo() {
    if (!mounted) return;
    _demo.forward(from: 0);
  }

  @override
  void dispose() {
    _demo.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _touch(Offset local) {
    setState(() {
      _trail.add(local);
      if (_trail.length > 40) _trail.removeAt(0);
    });
    final glyph = (local.dx / _box).floor();
    if (glyph < 0 || glyph >= widget.state.strokes.length) return;
    widget.onMove(
      glyph,
      Offset((local.dx - glyph * _box) / _box, local.dy / _box),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.state.strokes.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _box = math.min(constraints.maxHeight, constraints.maxWidth / n);
        return Container(
          width: _box * n,
          height: _box,
          decoration: BoxDecoration(
            color: AppColors.traceBoard,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: widget.accent, width: AppStroke.thick),
          ),
          child: Semantics(
            label: widget.state.glyphs.join(),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _touch(e.localPosition),
              onPointerMove: (e) => _touch(e.localPosition),
              onPointerUp: (_) => setState(_trail.clear),
              onPointerCancel: (_) => setState(_trail.clear),
              child: CustomPaint(
                size: Size(_box * n, _box),
                painter: _TracePainter(
                  state: widget.state,
                  box: _box,
                  accent: widget.accent,
                  demo: reduceMotion ? null : _demo,
                  pulse: _pulse,
                  trail: List.of(_trail),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.state,
    required this.box,
    required this.accent,
    required this.demo,
    required this.pulse,
    required this.trail,
  }) : super(repaint: Listenable.merge([demo, pulse]));

  final TraceState state;
  final double box;
  final Color accent;
  final Animation<double>? demo;
  final Animation<double> pulse;
  final List<Offset> trail;

  Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Path _path(List<Offset> pts, Offset origin) {
    final path = Path()
      ..moveTo(origin.dx + pts.first.dx * box, origin.dy + pts.first.dy * box);
    for (final p in pts.skip(1)) {
      path.lineTo(origin.dx + p.dx * box, origin.dy + p.dy * box);
    }
    return path;
  }

  Offset _at(Offset p, Offset origin) => origin + p * box;

  @override
  void paint(Canvas canvas, Size size) {
    final road = box * 0.15;
    final at = state.at;

    // The road, edge first so strokes join cleanly.
    for (final pass in [0, 1]) {
      for (final (g, strokes) in state.strokes.indexed) {
        final origin = Offset(g * box, 0);
        for (final s in strokes) {
          canvas.drawPath(
            _path(s, origin),
            pass == 0
                ? _line(AppColors.traceRoadEdge, road + box * 0.03)
                : _line(AppColors.traceRoad, road),
          );
        }
      }
    }

    // Guide dots on what is still to write.
    final dot = Paint()..color = AppColors.traceGuide;
    for (final (g, strokes) in state.strokes.indexed) {
      final origin = Offset(g * box, 0);
      for (final (si, s) in strokes.indexed) {
        final done = g < at.glyph || (g == at.glyph && si < at.stroke);
        if (done) continue;
        final from = g == at.glyph && si == at.stroke ? at.progress : 0;
        for (var i = from; i < s.length; i += 3) {
          canvas.drawCircle(_at(s[i], origin), box * 0.012, dot);
        }
      }
    }

    // Ink: what the child has written.
    final ink = _line(accent, road * 0.72);
    for (final (g, strokes) in state.strokes.indexed) {
      final origin = Offset(g * box, 0);
      for (final (si, s) in strokes.indexed) {
        if (g < at.glyph || (g == at.glyph && si < at.stroke)) {
          canvas.drawPath(_path(s, origin), ink);
        } else if (g == at.glyph && si == at.stroke && at.progress > 0) {
          canvas.drawPath(_path(s.sublist(0, at.progress + 1), origin), ink);
        }
      }
    }

    // The finger's own trail, so every touch shows something.
    if (trail.length > 1) {
      final path = Path()..moveTo(trail.first.dx, trail.first.dy);
      for (final p in trail.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, _line(accent.withValues(alpha: 0.3), road * 0.4));
    }

    final stroke = state.currentStroke;
    if (stroke == null) return;
    final origin = Offset(at.glyph * box, 0);

    // Arrows along the rest of the stroke show the way.
    final arrow = Paint()..color = AppColors.traceGuide;
    for (var i = at.progress + 6; i < stroke.length - 2; i += 9) {
      final a = _at(stroke[i], origin);
      final b = _at(stroke[i + 2], origin);
      final d = b - a;
      if (d.distance == 0) continue;
      final u = d / d.distance;
      final nrm = Offset(-u.dy, u.dx);
      final s = box * 0.035;
      canvas.drawPath(
        Path()
          ..moveTo(a.dx + u.dx * s, a.dy + u.dy * s)
          ..lineTo(a.dx - u.dx * s + nrm.dx * s, a.dy - u.dy * s + nrm.dy * s)
          ..lineTo(a.dx - u.dx * s - nrm.dx * s, a.dy - u.dy * s - nrm.dy * s)
          ..close(),
        arrow,
      );
    }

    // Where to put the finger: the green start dot, pulsing.
    final head = _at(stroke[at.progress], origin);
    final r = road * (0.55 + 0.12 * pulse.value);
    canvas
      ..drawCircle(head, r + box * 0.012, Paint()..color = AppColors.white)
      ..drawCircle(
        head,
        r,
        Paint()..color = at.progress == 0 ? AppColors.success : accent,
      );

    // Kido's demo finger slides along the stroke.
    final t = demo?.value;
    if (t != null && t > 0 && t < 1) {
      final i = (t * (stroke.length - 1)).round();
      final p = _at(stroke[i], origin);
      canvas
        ..drawCircle(p, road * 0.5, Paint()..color = AppColors.white)
        ..drawCircle(p, road * 0.4, Paint()..color = AppColors.kidoGreyDark);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.state != state ||
      old.box != box ||
      old.accent != accent ||
      old.trail.length != trail.length ||
      (old.trail.isNotEmpty && old.trail.last != trail.last);
}
