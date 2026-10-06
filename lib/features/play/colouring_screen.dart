import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/beckon.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_manager.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_widget.dart';
import 'colouring.dart';

/// Colouring: tap an area to fill it with the colour on the big button;
/// tap the button for the next colour (and hear its name).
class ColouringScreen extends ConsumerStatefulWidget {
  const ColouringScreen({super.key});

  @override
  ConsumerState<ColouringScreen> createState() => _ColouringScreenState();
}

class _ColouringScreenState extends ConsumerState<ColouringScreen> {
  final _confetti = BurstController();
  Timer? _adBreak;
  Size _canvas = Size.zero;

  ColouringController get _controller =>
      ref.read(colouringControllerProvider.notifier);

  @override
  void dispose() {
    _adBreak?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _react(ColouringState? prev, ColouringState next) {
    if (next.done > (prev?.done ?? 0)) {
      _confetti.fire();
      ref.read(kidoControllerProvider.notifier).act(KidoAction.trumpet);
      // A finished picture is a natural break: maybe an ad after the cheer.
      _adBreak?.cancel();
      _adBreak = Timer(AppDurations.celebration, () {
        if (!mounted) return;
        unawaited(
          ref
              .read(adManagerProvider)
              .maybeShowBreak(context, reason: 'colouring_done'),
        );
      });
    }
  }

  void _tap(Offset p) {
    final areas =
        colouringPages[ref.read(colouringControllerProvider).page].areas;
    // The top-most area under the finger.
    for (var i = areas.length - 1; i >= 0; i--) {
      if (areas[i](_canvas).contains(p)) {
        _controller.fill(i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(colouringControllerProvider, _react);
    final state = ref.watch(colouringControllerProvider);
    final l10n = AppLocalizations.of(context);
    final page = colouringPages[state.page];

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
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: PopIn(
                      key: ValueKey(page.id),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(
                            color: AppColors.outline,
                            width: AppStroke.thick,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _canvas = constraints.biggest;
                            return Semantics(
                              label: l10n.toyColouring,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (d) => _tap(d.localPosition),
                                child: CustomPaint(
                                  size: _canvas,
                                  painter: _PagePainter(page, state.fills),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              // The colour button (tap: next colour) and, when done, the
              // next picture.
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: BouncyButton(
                    semanticLabel: l10n.colouringColour,
                    sfx: null,
                    onPressed: () => unawaited(_controller.nextColour()),
                    child: AnimatedContainer(
                      duration: AppDurations.highlight,
                      width: AppSpacing.minTapTarget,
                      height: AppSpacing.minTapTarget,
                      decoration: BoxDecoration(
                        color: state.current,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outline,
                          width: AppStroke.thick,
                        ),
                      ),
                      child: const Icon(
                        Icons.brush_rounded,
                        size: AppSpacing.minTapTarget * 0.5,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Beckon(
                    active: state.complete,
                    strong: true,
                    child: ArrowButton(
                      direction: ArrowDirection.next,
                      color: AppColors.toyAccent,
                      onPressed: _controller.nextPage,
                    ),
                  ),
                ),
              ),
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

class _PagePainter extends CustomPainter {
  _PagePainter(this.page, this.fills);

  final ColouringPage page;
  final Map<int, Color> fills;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.thick
      ..strokeJoin = StrokeJoin.round;
    for (final (i, area) in page.areas.indexed) {
      final path = area(size);
      canvas
        ..drawPath(path, Paint()..color = fills[i] ?? AppColors.white)
        ..drawPath(path, outline);
    }
  }

  @override
  bool shouldRepaint(_PagePainter old) =>
      old.page != page || !mapEquals(old.fills, fills);
}
