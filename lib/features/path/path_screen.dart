import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/beckon.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../games/games_screen.dart';
import '../games/quiz_models.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_voice.dart';
import '../kido/kido_widget.dart';
import '../play/toys.dart';
import '../section_grid/section_items.dart';
import 'daily_path.dart';

/// Kido's daily path: five stepping stones on a winding road. The glowing
/// stone is next; finished stones wear a star; a trophy waits at the end.
class PathScreen extends ConsumerStatefulWidget {
  const PathScreen({super.key});

  @override
  ConsumerState<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends ConsumerState<PathScreen> {
  final _confetti = BurstController();
  final _stoneKeys = List.generate(6, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = ref.read(dailyPathProvider);
      unawaited(
        ref
            .read(kidoVoiceProvider)
            .say(path.finished ? KidoEvent.pathDone : KidoEvent.pathStart),
      );
      _pointAtCurrent();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _pointAtCurrent() {
    final current = ref.read(dailyPathProvider).current;
    final box =
        _stoneKeys[current ?? 5].currentContext?.findRenderObject()
            as RenderBox?;
    if (box == null || !box.attached) return;
    ref
        .read(kidoControllerProvider.notifier)
        .act(
          KidoAction.point,
          target: box.localToGlobal(box.size.center(Offset.zero)),
        );
  }

  String? _image(PathStep step) {
    final catalog = ref.read(contentCatalogProvider).value;
    return switch (step.kind) {
      PathKind.learn || PathKind.trace => catalog?.itemById(step.ref)?.image,
      PathKind.game => GamesScreen.imageFor(
        GameKind.values.asNameMap()[step.ref] ?? GameKind.findIt,
      ),
      PathKind.toy =>
        (ToyKind.values.asNameMap()[step.ref] ?? ToyKind.tapPlay).image,
    };
  }

  String? _route(PathStep step) {
    final item = ref.read(contentCatalogProvider).value?.itemById(step.ref);
    ItemScope scopeOf(SectionId section) => (
      section: section,
      row: section == SectionId.numbers && item?.number != null
          ? (item!.number! - 1) ~/ 10 + 1
          : null,
    );
    return switch (step.kind) {
      PathKind.learn when item != null => AppRoutes.learn(
        scopeOf(item.section),
        item.id,
      ),
      PathKind.trace when item != null => AppRoutes.trace(
        scopeOf(item.section),
        item.id,
      ),
      PathKind.game => switch (GameKind.values.asNameMap()[step.ref]) {
        final kind? => AppRoutes.game(kind),
        null => null,
      },
      PathKind.toy => switch (ToyKind.values.asNameMap()[step.ref]) {
        final kind? => AppRoutes.toy(kind),
        null => null,
      },
      _ => null,
    };
  }

  void _open(int index) {
    final path = ref.read(dailyPathProvider);
    final current = path.current;
    // One step at a time: a later stone just points back to the next one.
    if (current != null && index > current) {
      ref.read(audioServiceProvider).playSfx(Sfx.pop);
      _pointAtCurrent();
      return;
    }
    final route = _route(path.steps[index]);
    // Back from the activity returns here.
    if (route != null) unawaited(context.push(route));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dailyPathProvider, (prev, next) {
      if (next.celebrations > (prev?.celebrations ?? 0)) {
        _confetti.fire();
        ref.read(kidoControllerProvider.notifier).act(KidoAction.trumpet);
        unawaited(ref.read(kidoVoiceProvider).say(KidoEvent.pathDone));
      }
    });
    final path = ref.watch(dailyPathProvider);
    final l10n = AppLocalizations.of(context);
    final steps = path.steps;
    final current = path.current;

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.md,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final n = steps.length + 1; // + the trophy
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    // Neighbours sit on alternate rows, so stones can be
                    // wider than their spacing: as big as fits (two rows
                    // high, no overlap with the next-but-one stone).
                    final stone = math
                        .min(h * 0.46, 1.8 * w / (n - 1 + 1.8))
                        .clamp(AppSpacing.minTapTarget * 0.8, 150.0);
                    final step = (w - stone) / math.max(1, n - 1);
                    // Stones zig-zag between a low and a high row.
                    Offset centre(int i) => Offset(
                      stone / 2 + i * step,
                      i.isEven ? h - stone / 2 : stone / 2,
                    );
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RoadPainter([
                              for (var i = 0; i < n; i++) centre(i),
                            ]),
                          ),
                        ),
                        for (var i = 0; i < steps.length; i++)
                          Positioned(
                            left: centre(i).dx - stone / 2,
                            top: centre(i).dy - stone / 2,
                            width: stone,
                            height: stone,
                            child: PopIn(
                              index: i,
                              child: Beckon(
                                key: _stoneKeys[i],
                                active: i == current,
                                strong: true,
                                child: BouncyButton(
                                  semanticLabel: l10n.pathStep(i + 1),
                                  onPressed: () => _open(i),
                                  child: _Stone(
                                    image: _image(steps[i]),
                                    done: path.isDone(steps[i]),
                                    later: current != null && i > current,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: centre(n - 1).dx - stone / 2,
                          top: centre(n - 1).dy - stone / 2,
                          width: stone,
                          height: stone,
                          child: PopIn(
                            index: n,
                            child: KeyedSubtree(
                              key: _stoneKeys[5],
                              child: _Trophy(
                                won: path.finished,
                                count: path.trophies,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
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

class _Stone extends StatelessWidget {
  const _Stone({required this.image, required this.done, required this.later});

  final String? image;
  final bool done;
  final bool later;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ItemPicture(
            image: image ?? '',
            fallbackText: '',
            accent: done ? AppColors.success : AppColors.toyAccent,
          ),
        ),
        // Later steps wait under a soft veil (solid, so the road beneath
        // never shows through).
        if (later)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.pathVeil,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
            ),
          ),
        if (done)
          const Positioned(
            right: -AppSpacing.sm,
            top: -AppSpacing.sm,
            child: Icon(
              Icons.star_rounded,
              color: AppColors.celebrate,
              size: AppSpacing.xxl,
              shadows: [Shadow(color: AppColors.outline, blurRadius: 3)],
            ),
          ),
      ],
    );
  }
}

/// The end of the road: a trophy that lights up when the path is done.
class _Trophy extends StatelessWidget {
  const _Trophy({required this.won, required this.count});

  final bool won;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: won ? AppColors.celebrate : AppColors.traceRoad,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              child: Icon(
                Icons.emoji_events_rounded,
                color: won ? AppColors.white : AppColors.traceGuide,
                size: AppSpacing.xxl,
              ),
            ),
          ),
          if (count > 0)
            Text('$count', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// A dotted, winding road through the stones.
class _RoadPainter extends CustomPainter {
  _RoadPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final mid = (a.dx + b.dx) / 2;
      path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.traceRoadEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.traceRoad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.points != points;
}
