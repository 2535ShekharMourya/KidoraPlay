import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/level.dart';
import '../../content/models/section.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/beckon.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../core/widgets/wiggle.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_manager.dart';
import '../kido/hint_timer.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_widget.dart';
import '../numbers/place_value_view.dart';
import '../progress/progress_controller.dart';
import '../progress/sticker_widgets.dart';
import '../rewards/balloon_party.dart';
import '../section_grid/section_items.dart';
import '../tracing/trace_logic.dart';
import 'counting_stars.dart';
import 'learn_card_controller.dart';
import 'spelling_strip.dart';
import 'star_meter.dart';

/// Reusable learn card for any item: big picture, the word (English and/or
/// Hindi), place value for numbers, the spelling strip, and Kido teaching
/// "I do, we do, you do". Opens straight into the lesson.
class LearnCardScreen extends ConsumerStatefulWidget {
  const LearnCardScreen({required this.scope, required this.itemId, super.key});

  final ItemScope scope;
  final String itemId;

  @override
  ConsumerState<LearnCardScreen> createState() => _LearnCardScreenState();
}

class _LearnCardScreenState extends ConsumerState<LearnCardScreen> {
  final _burst = BurstController();
  final _pictureKey = GlobalKey();
  final _jarKey = GlobalKey();
  int _celebrationKey = 0;

  /// Balloon party on screen (learned pictures of this set).
  List<LearningItem>? _party;
  Timer? _adBreak;
  List<GlobalKey> _tileKeys = const [];

  LearnCardController get _controller =>
      ref.read(learnCardControllerProvider(widget.itemId).notifier);
  KidoController get _kido => ref.read(kidoControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _controller.attach(widget.scope);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    _adBreak?.cancel();
    _burst.dispose();
    super.dispose();
  }

  Offset? _centerOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _flySticker() {
    final item = ref
        .read(scopeItemsProvider(widget.scope))
        .where((i) => i.id == widget.itemId)
        .firstOrNull;
    final from = _rectOf(_pictureKey);
    final to = _rectOf(_jarKey);
    if (item == null || from == null || to == null) return;
    flySticker(context, image: item.image, from: from, to: to);
  }

  final _warmed = <String>{};

  /// Decodes the neighbours' pictures ahead, so next/previous is instant.
  void _warmNeighbours(List<LearningItem> items, int index) {
    final images = [
      for (final i in [index - 1, index + 1])
        if (i >= 0 && i < items.length) items[i].image,
    ].where(_warmed.add).toList();
    if (images.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final image in images) {
        unawaited(
          precacheImage(AssetImage(image), context, onError: (_, _) {}),
        );
      }
    });
  }

  GlobalKey? _tileKey(int? index) =>
      index != null && index < _tileKeys.length ? _tileKeys[index] : null;

  /// Turns lesson changes into Kido's body language.
  void _directKido(LearnCardState? prev, LearnCardState next) {
    final target = _centerOf(_pictureKey);

    if (next.celebrations > (prev?.celebrations ?? 0)) {
      _burst.fire();
      _kido.act(KidoAction.clap);
      return;
    }
    if (next.completions > (prev?.completions ?? 0)) {
      setState(() => _celebrationKey++);
      _kido.act(KidoAction.trumpet);
      // A finished section is a natural break: after the celebration,
      // maybe an ad (the manager decides; usually not).
      _adBreak?.cancel();
      _adBreak = Timer(AppDurations.celebration, () {
        if (!mounted) return;
        unawaited(
          ref
              .read(adManagerProvider)
              .maybeShowBreak(context, reason: 'section_done'),
        );
      });
      return;
    }
    if (next.stickers > (prev?.stickers ?? 0)) {
      _flySticker();
    }
    if (next.parties > (prev?.parties ?? 0)) {
      final progress = ref.read(progressProvider);
      final learned = ref
          .read(scopeItemsProvider(widget.scope))
          .where((i) => progress.isLearned(i.id))
          .toList();
      setState(() => _party = learned);
      _kido.act(KidoAction.trumpet);
      return;
    }
    if (next.stars > (prev?.stars ?? 0)) {
      // A star earned: sparkle on the picture and a clap from Kido.
      _burst.fire();
      _kido.act(KidoAction.clap);
      return;
    }
    if (next.cheers > (prev?.cheers ?? 0)) {
      _kido.act(KidoAction.trumpet);
      return;
    }
    if (next.highlighted != null && next.highlighted != prev?.highlighted) {
      _kido.act(
        KidoAction.spellTap,
        target: _centerOf(_tileKey(next.highlighted)),
      );
      return;
    }
    if (next.hint != prev?.hint) {
      switch (next.hint) {
        case HintLevel.look:
          _kido.act(KidoAction.look, target: target);
        case HintLevel.point || HintLevel.glow:
          _kido.act(KidoAction.point, target: target);
        case HintLevel.none:
          break;
      }
    }
    if (next.phase != prev?.phase) {
      switch (next.phase) {
        case LessonPhase.iDo || LessonPhase.youDo:
          _kido.act(KidoAction.point, target: target);
        case LessonPhase.done || LessonPhase.idle:
          break;
      }
    }
  }

  /// Numbers up to 20 show countable stars; everything else its picture.
  Widget _picture(LearningItem item, LearnCardState state, Color accent) {
    final n = item.number;
    if (n != null && n <= AppDurations.countAlongMax) {
      return CountingStars(number: n, counted: state.counted, accent: accent);
    }
    return ItemPicture(
      image: item.image,
      fallbackText: item.wordEn,
      accent: accent,
      badge: item.badge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(scopeItemsProvider(widget.scope));
    final index = items.indexWhere((i) => i.id == widget.itemId);
    final theme = SectionTheme.of(widget.scope.section);

    ref.listen(learnCardControllerProvider(widget.itemId), _directKido);

    if (index < 0) {
      // Unknown item or not in the selected class: just offer the way back.
      return Scaffold(
        body: SectionBackground(
          section: widget.scope.section,
          child: const SafeArea(
            child: Align(alignment: Alignment.topLeft, child: BigBackButton()),
          ),
        ),
      );
    }

    final item = items[index];
    _warmNeighbours(items, index);
    final tiles = item.spelling;
    if (_tileKeys.length != tiles.length) {
      _tileKeys = [for (final _ in tiles) GlobalKey()];
    }
    final state = ref.watch(learnCardControllerProvider(widget.itemId));
    final languages = ref.watch(
      settingsProvider.select((s) => s.language.languages),
    );
    // The picture calls for a tap when the child goes quiet.
    final pictureBeckons =
        state.phase == LessonPhase.youDo &&
        !state.busy &&
        (state.hint == HintLevel.point || state.hint == HintLevel.glow);

    final canTrace =
        ref.watch(traceGuidesProvider).value?.glyphsFor(item) != null;

    void goTo(LearningItem other) =>
        context.go(AppRoutes.learn(widget.scope, other.id));

    return Scaffold(
      body: Listener(
        // Any tap resets the idle hints.
        onPointerDown: (_) => _controller.userTapped(),
        child: SectionBackground(
          section: widget.scope.section,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.sideZone,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: PopIn(
                                    key: ValueKey(item.id),
                                    child: ParticleBurst(
                                      controller: _burst,
                                      child: _CountBubble(
                                        count: state.counted,
                                        color: theme.accent,
                                        child: Beckon(
                                          key: _pictureKey,
                                          active: pictureBeckons,
                                          strong: state.hint == HintLevel.glow,
                                          child: IdleFloat(
                                            child: Wiggle(
                                              active: state.reacting,
                                              child: BouncyButton(
                                                semanticLabel: item.wordEn,
                                                sfx: null,
                                                onPressed:
                                                    _controller.tapPicture,
                                                child: _picture(
                                                  item,
                                                  state,
                                                  theme.accent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: PopIn(
                                key: ValueKey('word-${item.id}'),
                                index: 1,
                                child: _WordPanel(
                                  item: item,
                                  // Hindi letters: the Hindi word first.
                                  languages: item.section == SectionId.hindi
                                      ? const [
                                          ContentLanguage.hi,
                                          ContentLanguage.en,
                                        ]
                                      : languages,
                                  section: widget.scope.section,
                                  stars: state.stars,
                                  starGoal: state.starGoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: !item.section.hasSpelling
                            ? _BigLetter(
                                letter: item.letter ?? '',
                                accent: theme.accent,
                                onTap: _controller.tapBigLetter,
                              )
                            : SpellingStrip(
                                tiles: tiles,
                                revealed: state.revealed,
                                highlighted: state.highlighted,
                                accent: theme.accent,
                                onTapLetter: _controller.tapLetter,
                                tileKeys: _tileKeys,
                              ),
                      ),
                    ],
                  ),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: BigBackButton(),
                ),
                if (index > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: ArrowButton(
                        direction: ArrowDirection.previous,
                        color: theme.accent,
                        onPressed: () => goTo(items[index - 1]),
                      ),
                    ),
                  ),
                if (index < items.length - 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      // All stars earned: the way on glows and bounces.
                      child: Beckon(
                        active: state.phase == LessonPhase.done,
                        strong: true,
                        child: ArrowButton(
                          direction: ArrowDirection.next,
                          color: theme.accent,
                          onPressed: () => goTo(items[index + 1]),
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: IgnorePointer(
                      child: KeyedSubtree(
                        key: _jarKey,
                        child: StickerJar(
                          count: ref
                              .watch(
                                sectionProgressProvider(widget.scope.section),
                              )
                              .learned,
                        ),
                      ),
                    ),
                  ),
                ),
                if (canTrace)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _WriteButton(
                        color: theme.accent,
                        onPressed: () {
                          _controller.pause();
                          context.go(AppRoutes.trace(widget.scope, item.id));
                        },
                      ),
                    ),
                  ),
                const KidoCorner(),
                if (_party case final party? when party.isNotEmpty)
                  Positioned.fill(
                    child: BalloonParty(
                      items: party,
                      onDone: () {
                        setState(() => _party = null);
                        unawaited(_controller.partyOver());
                      },
                    ),
                  ),
                if (_celebrationKey > 0)
                  Positioned.fill(
                    child: CelebrationOverlay(
                      key: ValueKey(_celebrationKey),
                      image: item.image,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pencil button: write this letter or number with a finger.
class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IdleFloat(
      phase: 0.5,
      child: BouncyButton(
        semanticLabel: AppLocalizations.of(context).traceIt,
        onPressed: onPressed,
        child: Container(
          width: AppSpacing.minTapTarget,
          height: AppSpacing.minTapTarget,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outline,
              width: AppStroke.thick,
            ),
          ),
          child: const Icon(
            Icons.draw_rounded,
            size: AppSpacing.minTapTarget * 0.55,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// Shows Kido's count ("1", "2", "3"…) popping over the picture's corner.
class _CountBubble extends StatelessWidget {
  const _CountBubble({
    required this.count,
    required this.color,
    required this.child,
  });

  final int count;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: -AppSpacing.md,
          top: -AppSpacing.md,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : AppDurations.highlight,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: AppCurves.tap),
                child: child,
              ),
              child: count == 0
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(count),
                      width: AppSpacing.xxl * 1.3,
                      height: AppSpacing.xxl * 1.3,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outline,
                          width: AppStroke.thick,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.white),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hindi letter cards: the letter, big, where the spelling strip would be.
class _BigLetter extends StatelessWidget {
  const _BigLetter({
    required this.letter,
    required this.accent,
    required this.onTap,
  });

  final String letter;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: BouncyButton(
          semanticLabel: letter,
          sfx: null,
          onPressed: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.outline,
                width: AppStroke.thick,
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.displayLarge
                      ?.copyWith(color: AppColors.white, height: 1.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordPanel extends StatelessWidget {
  const _WordPanel({
    required this.item,
    required this.languages,
    required this.section,
    required this.stars,
    required this.starGoal,
  });

  final LearningItem item;
  final List<ContentLanguage> languages;
  final SectionId section;
  final int stars;
  final int starGoal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final number = item.number;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (starGoal > 0) StarMeter(stars: stars, goal: starGoal),
        // The first word is the one being taught, so it is the big one.
        for (final (i, lang) in languages.indexed)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.word(lang),
              style: i == 0
                  ? text.displayLarge?.copyWith(fontSize: 48)
                  : text.headlineMedium?.copyWith(fontSize: 34),
            ),
          ),
        // Place value for bigger numbers (up to 20 the stars show it).
        if (number != null && number > AppDurations.countAlongMax) ...[
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: PlaceValueView(
              number: number,
              tensColor: SectionTheme.of(section).accent,
              onesColor: AppColors.placeOnes,
            ),
          ),
        ],
      ],
    );
  }
}
