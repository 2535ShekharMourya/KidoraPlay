import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/level.dart';
import '../../core/audio/audio_service.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/beckon.dart';
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
import 'story.dart';
import 'story_controller.dart';

/// The story shelf: a cover per story for the child's class.
class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(settingsProvider.select((s) => s.level));
    final lang = ref.watch(
      settingsProvider.select((s) => s.language.talkLanguages.first),
    );
    final stories = [
      for (final s in ref.watch(storiesProvider).value ?? const <Story>[])
        if (s.levels.contains(level)) s,
    ];
    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PagedTiles(
                  count: stories.length,
                  maxColumns: 4,
                  minHeight: AppLayout.sectionTileMinHeight,
                  arrowColor: AppColors.storyAccent,
                  builder: (context, i, slot) {
                    final story = stories[i];
                    return PopIn(
                      index: slot,
                      child: IdleFloat(
                        phase: (i * 0.37) % 1,
                        child: BouncyButton(
                          semanticLabel: story.titleEn,
                          onPressed: () {
                            // Hear the title while the book opens.
                            unawaited(
                              ref
                                  .read(audioServiceProvider)
                                  .playVoice(story.titleVoice(lang)),
                            );
                            context.go(AppRoutes.story(story.id));
                          },
                          child: _Cover(story: story, lang: lang),
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

class _Cover extends StatelessWidget {
  const _Cover({required this.story, required this.lang});

  final Story story;
  final ContentLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.storyAccent,
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
                story.cover,
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
              child: Text(
                story.title(lang),
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

/// Reads one story: the picture, the words, and big page arrows.
class StoryReaderScreen extends ConsumerStatefulWidget {
  const StoryReaderScreen({required this.storyId, super.key});

  final String storyId;

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderState();
}

class _StoryReaderState extends ConsumerState<StoryReaderScreen> {
  final _confetti = BurstController();
  Timer? _adBreak;
  bool _opened = false;

  StoryController get _controller =>
      ref.read(storyControllerProvider(widget.storyId).notifier);

  @override
  void dispose() {
    _adBreak?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _react(StoryState? prev, StoryState next) {
    if (next.celebrations > (prev?.celebrations ?? 0)) {
      _confetti.fire();
      ref.read(kidoControllerProvider.notifier).act(KidoAction.trumpet);
      // The end of a story is a natural break: maybe an ad after the cheer.
      _adBreak?.cancel();
      _adBreak = Timer(AppDurations.celebration, () {
        if (!mounted) return;
        unawaited(
          ref
              .read(adManagerProvider)
              .maybeShowBreak(context, reason: 'story_done'),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(storyControllerProvider(widget.storyId), _react);
    final stories = ref.watch(storiesProvider).value ?? const <Story>[];
    final story = stories.where((s) => s.id == widget.storyId).firstOrNull;
    final state = ref.watch(storyControllerProvider(widget.storyId));
    final languages = ref.watch(
      settingsProvider.select((s) => s.language.languages),
    );
    final l10n = AppLocalizations.of(context);

    if (story == null) {
      return const Scaffold(
        body: SafeArea(
          child: Align(alignment: Alignment.topLeft, child: BigBackButton()),
        ),
      );
    }
    if (!_opened) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.open(story));
      });
    }
    final main = _controller.language;
    final other = languages.where((l) => l != main).firstOrNull;
    final page = story.pages[state.page];

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
                child: state.atEnd
                    ? _TheEnd(
                        story: story,
                        lang: main,
                        onAgain: _controller.again,
                        label: l10n.storyAgain,
                      )
                    : Row(
                        children: [
                          // The picture: tap to hear the page again.
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: PopIn(
                                  key: ValueKey(state.page),
                                  child: BouncyButton(
                                    semanticLabel: page.textEn,
                                    sparkle: false,
                                    onPressed: _controller.replay,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.card,
                                      ),
                                      child: Image.asset(
                                        page.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: _Words(
                              key: ValueKey('w${state.page}'),
                              main: page.text(main),
                              other: other == null ? null : page.text(other),
                              page: state.page,
                              pages: story.pages.length,
                            ),
                          ),
                        ],
                      ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              if (!state.atEnd && state.page > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ArrowButton(
                      direction: ArrowDirection.previous,
                      color: AppColors.storyAccent,
                      onPressed: _controller.previous,
                    ),
                  ),
                ),
              if (!state.atEnd)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    // Glows once the page has been read: turn the page!
                    child: Beckon(
                      active: !state.narrating,
                      strong: true,
                      child: ArrowButton(
                        direction: ArrowDirection.next,
                        color: AppColors.storyAccent,
                        onPressed: _controller.next,
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

/// The page's words: big in the reading language, small in the other one,
/// with a dot per page.
class _Words extends StatelessWidget {
  const _Words({
    required this.main,
    required this.other,
    required this.page,
    required this.pages,
    super.key,
  });

  final String main;
  final String? other;
  final int page;
  final int pages;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < pages; i++)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(
                  i == page ? Icons.circle : Icons.circle_outlined,
                  size: AppSpacing.md,
                  color: AppColors.storyAccent,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // The words always fit: they wrap to the width and, on a small
        // screen, shrink rather than being cut off.
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: constraints.maxWidth,
                child: PopIn(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        main,
                        style: text.headlineMedium?.copyWith(height: 1.3),
                      ),
                      if (other != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          other!,
                          style: text.titleMedium?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TheEnd extends StatelessWidget {
  const _TheEnd({
    required this.story,
    required this.lang,
    required this.onAgain,
    required this.label,
  });

  final Story story;
  final ContentLanguage lang;
  final VoidCallback onAgain;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: PopIn(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: Image.asset(story.cover, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopIn(
                index: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.storyTheEnd,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PopIn(
                index: 2,
                child: BouncyButton(
                  semanticLabel: label,
                  sfx: Sfx.whoosh,
                  onPressed: onAgain,
                  child: Container(
                    width: AppSpacing.minTapTarget,
                    height: AppSpacing.minTapTarget,
                    decoration: BoxDecoration(
                      color: AppColors.storyAccent,
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
            ],
          ),
        ),
      ],
    );
  }
}
