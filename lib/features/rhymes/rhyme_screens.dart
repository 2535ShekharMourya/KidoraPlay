import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_service.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/paged_tiles.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_manager.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_widget.dart';
import 'rhyme.dart';

/// The rhymes shelf for the child's class.
class RhymesScreen extends ConsumerWidget {
  const RhymesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(settingsProvider.select((s) => s.level));
    final rhymes = [
      for (final r in ref.watch(rhymesProvider).value ?? const <Rhyme>[])
        if (r.levels.contains(level)) r,
    ];
    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PagedTiles(
                  count: rhymes.length,
                  maxColumns: 4,
                  minHeight: AppLayout.sectionTileMinHeight,
                  arrowColor: AppColors.rhymeAccent,
                  builder: (context, i, slot) {
                    final r = rhymes[i];
                    return PopIn(
                      index: slot,
                      child: IdleFloat(
                        phase: (i * 0.37) % 1,
                        child: BouncyButton(
                          semanticLabel: r.titleEn,
                          onPressed: () => context.go(AppRoutes.rhyme(r.id)),
                          child: _RhymeCover(rhyme: r),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              const KidoCorner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RhymeCover extends StatelessWidget {
  const _RhymeCover({required this.rhyme});

  final Rhyme rhyme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.rhymeAccent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card - 6),
              child: Image.asset(
                rhyme.image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              // The title in the rhyme's own language.
              child: Text(
                rhyme.title(rhyme.language),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays one rhyme: the picture bounces to the tune, the line being sung
/// lights up.
class RhymePlayerScreen extends ConsumerStatefulWidget {
  const RhymePlayerScreen({required this.rhymeId, super.key});

  final String rhymeId;

  @override
  ConsumerState<RhymePlayerScreen> createState() => _RhymePlayerState();
}

class _RhymePlayerState extends ConsumerState<RhymePlayerScreen> {
  final _confetti = BurstController();
  Timer? _adBreak;
  bool _started = false;

  RhymeController get _controller =>
      ref.read(rhymeControllerProvider(widget.rhymeId).notifier);

  @override
  void dispose() {
    _adBreak?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _react(RhymeState? prev, RhymeState next) {
    if (next.finished > (prev?.finished ?? 0)) {
      _confetti.fire();
      ref.read(kidoControllerProvider.notifier).act(KidoAction.trumpet);
      // The end of a rhyme is a natural break: maybe an ad after the cheer.
      _adBreak?.cancel();
      _adBreak = Timer(AppDurations.celebration, () {
        if (!mounted) return;
        unawaited(
          ref
              .read(adManagerProvider)
              .maybeShowBreak(context, reason: 'rhyme_done'),
        );
      });
    } else if (next.beat > (prev?.beat ?? 0) && next.beat % 4 == 0) {
      // Kido claps along now and then.
      ref.read(kidoControllerProvider.notifier).act(KidoAction.clap);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(rhymeControllerProvider(widget.rhymeId), _react);
    final rhyme = (ref.watch(rhymesProvider).value ?? const <Rhyme>[])
        .where((r) => r.id == widget.rhymeId)
        .firstOrNull;
    final state = ref.watch(rhymeControllerProvider(widget.rhymeId));
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (rhyme == null) {
      return const Scaffold(
        body: SafeArea(
          child: Align(alignment: Alignment.topLeft, child: BigBackButton()),
        ),
      );
    }
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.play(rhyme));
      });
    }
    final text = Theme.of(context).textTheme;

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
                child: Row(
                  children: [
                    // The picture bounces on every note.
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: AnimatedScale(
                            scale: reduceMotion || state.beat.isEven ? 1 : 1.05,
                            duration: AppDurations.highlight,
                            curve: AppCurves.tap,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                              child: Image.asset(
                                rhyme.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // The words: the line being sung is big and bright.
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (i, line) in rhyme.lines.indexed)
                                  AnimatedDefaultTextStyle(
                                    duration: AppDurations.highlight,
                                    style:
                                        (i == state.line
                                            ? text.headlineMedium?.copyWith(
                                                color: AppColors.rhymeAccent,
                                              )
                                            : text.titleMedium?.copyWith(
                                                color: AppColors.outline,
                                              )) ??
                                        const TextStyle(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Text(line.text),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              // Sing it again (when it has finished).
              if (!state.playing)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: PopIn(
                      child: BouncyButton(
                        semanticLabel: l10n.rhymeAgain,
                        sfx: Sfx.whoosh,
                        onPressed: () => unawaited(_controller.play(rhyme)),
                        child: Container(
                          width: AppSpacing.minTapTarget,
                          height: AppSpacing.minTapTarget,
                          decoration: BoxDecoration(
                            color: AppColors.rhymeAccent,
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
          ),
        ),
      ),
    );
  }
}

/// Home tile for the rhymes shelf.
class RhymesTile extends StatelessWidget {
  const RhymesTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BouncyButton(
      semanticLabel: l10n.rhymes,
      onPressed: () => context.go(AppRoutes.rhymes),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.rhymeAccent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            const Expanded(
              child: FittedBox(
                child: Icon(Icons.music_note_rounded, color: AppColors.white),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.rhymes,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
