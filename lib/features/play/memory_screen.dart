import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../core/widgets/tile_layout.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_manager.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_widget.dart';
import 'memory_controller.dart';

/// Memory match: face-down cards; find the pairs.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _confetti = BurstController();
  Timer? _adBreak;
  bool _started = false;

  MemoryController get _controller =>
      ref.read(memoryControllerProvider.notifier);

  @override
  void dispose() {
    _adBreak?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _react(MemoryState? prev, MemoryState next) {
    final kido = ref.read(kidoControllerProvider.notifier);
    if (next.games > (prev?.games ?? 0)) {
      _confetti.fire();
      kido.act(KidoAction.trumpet);
      // A finished game is a natural break: maybe an ad after the cheer.
      _adBreak?.cancel();
      _adBreak = Timer(AppDurations.celebration, () {
        if (!mounted) return;
        unawaited(
          ref
              .read(adManagerProvider)
              .maybeShowBreak(context, reason: 'memory_done'),
        );
      });
    } else if (next.matches > (prev?.matches ?? 0)) {
      kido.act(KidoAction.clap);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(memoryControllerProvider, _react);
    final state = ref.watch(memoryControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = TileLayout.fit(
                Size(
                  constraints.maxWidth - AppLayout.sideZone * 2,
                  constraints.maxHeight - AppSpacing.md * 2,
                ),
                square: true,
                maxColumns: 6,
                maxRows: 3,
              );
              if (!_started) {
                _started = true;
                // As many cards as fit the screen at full size.
                final fit = layout.perPage - layout.perPage % 2;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _controller.start(maxCards: fit);
                });
              }
              final cards = state.cards;
              final cols = _columnsFor(cards.length, layout.columns);
              const gap = AppSpacing.tapGap;
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.sideZone,
                      vertical: AppSpacing.md,
                    ),
                    child: Center(
                      child: Column(
                        key: ValueKey(state.games),
                        mainAxisSize: MainAxisSize.min,
                        spacing: gap,
                        children: [
                          for (var r = 0; r * cols < cards.length; r++)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: gap,
                              children: [
                                for (
                                  var i = r * cols;
                                  i < cards.length && i < (r + 1) * cols;
                                  i++
                                )
                                  SizedBox.fromSize(
                                    size: layout.tile,
                                    child: PopIn(
                                      index: i,
                                      child: BouncyButton(
                                        semanticLabel: cards[i].faceUp
                                            ? cards[i].item.wordEn
                                            : l10n.memoryCard,
                                        sfx: null,
                                        onPressed: () => _controller.tap(i),
                                        child: _Card(card: cards[i]),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: BigBackButton(),
                  ),
                  if (state.finished)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: PopIn(
                          child: BouncyButton(
                            semanticLabel: l10n.playAgain,
                            sfx: Sfx.whoosh,
                            onPressed: _controller.start,
                            child: Container(
                              width: AppSpacing.minTapTarget,
                              height: AppSpacing.minTapTarget,
                              decoration: BoxDecoration(
                                color: AppColors.toyAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outline,
                                  width: AppStroke.thick,
                                ),
                              ),
                              child: const Icon(
                                Icons.replay_rounded,
                                size: AppSpacing.minTapTarget * 0.55,
                                color: AppColors.white,
                              ),
                            ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  /// Rows as even as possible (6 cards: 3 + 3, not 5 + 1).
  static int _columnsFor(int cards, int maxColumns) {
    if (cards == 0) return 1;
    final rows = (cards / maxColumns).ceil();
    return (cards / rows).ceil();
  }
}

/// One card: a bright back with a star, or the picture when turned up.
class _Card extends StatelessWidget {
  const _Card({required this.card});

  final MemoryCard card;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppDurations.cardFlip,
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        // A flip: squeeze to nothing and open again.
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(animation.value, 1, 1),
          child: child,
        ),
      ),
      child: card.faceUp
          ? Opacity(
              key: const ValueKey('up'),
              opacity: 1,
              child: ItemPicture(
                image: card.item.image,
                fallbackText: card.item.wordEn,
                accent: card.matched ? AppColors.success : AppColors.toyAccent,
              ),
            )
          : Container(
              key: const ValueKey('down'),
              decoration: BoxDecoration(
                color: AppColors.toyAccent,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.outline,
                  width: AppStroke.thick,
                ),
              ),
              child: const FittedBox(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Icon(Icons.star_rounded, color: AppColors.white),
                ),
              ),
            ),
    );
  }
}
