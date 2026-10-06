import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../core/widgets/tile_layout.dart';
import '../../content/models/kido_line.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_memory.dart';
import '../kido/kido_voice.dart';
import '../kido/kido_widget.dart';
import '../path/path_tile.dart';
import '../rhymes/rhyme_screens.dart';
import '../stories/stories_tile.dart';
import '../progress/progress_controller.dart';
import '../progress/sticker_book_screen.dart';
import '../progress/sticker_widgets.dart';

/// Section menu. Kido waves hello (a full welcome the very first time, a
/// short one after that, once per session). Tapping a tile says the
/// section name and opens it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  Future<void> _greet() async {
    final memory = ref.read(kidoMemoryProvider);
    if (!mounted || !memory.takeSessionGreeting()) return;
    final first = !memory.welcomed;
    ref.read(kidoControllerProvider.notifier).act(KidoAction.wave);
    await ref
        .read(kidoVoiceProvider)
        .say(first ? KidoEvent.welcomeFirst : KidoEvent.welcomeBack);
    if (first) await memory.markWelcomed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(contentCatalogProvider).value;

    void open(SectionId id) {
      final section = catalog?.section(id);
      // First visit: the section greets with "Let's learn …!" instead.
      if (section != null && ref.read(kidoMemoryProvider).visited(id)) {
        final languages = ref.read(settingsProvider).language.languages;
        ref.read(audioServiceProvider).playVoiceSequence([
          for (final l in languages) section.voice(l),
        ]);
      }
      context.go(AppRoutes.section(id));
    }

    final sections = <Object>[
      HomeExtra.path, // Today's path, always first.
      HomeExtra.stories,
      HomeExtra.rhymes,
      for (final s
          in catalog?.sectionsFor(ref.watch(settingsProvider).level) ??
              const <Section>[])
        s.id,
    ];
    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Up to two rows of five; fewer, bigger tiles on small phones,
              // with the rest on the next page.
              final layout = TileLayout.fit(
                Size(
                  constraints.maxWidth - AppLayout.sideZone * 2,
                  constraints.maxHeight - AppSpacing.md * 2,
                ),
                minHeight: AppLayout.sectionTileMinHeight,
              );
              final pages = layout.pagesFor(sections.length);
              final page = _page.clamp(0, pages - 1);
              final shown = sections
                  .skip(page * layout.perPage)
                  .take(layout.perPage)
                  .toList();
              return Stack(
                children: [
                  Padding(
                    // The left column is Kido's and the right one holds the
                    // sticker book and games; tiles never sit under either.
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.sideZone,
                      vertical: AppSpacing.md,
                    ),
                    child: _SectionGrid(
                      // A new page pops in afresh.
                      key: ValueKey(page),
                      sections: shown,
                      layout: layout,
                      labelOf: (id) => sectionLabel(l10n, id),
                      imageOf: (id) => catalog?.section(id)?.image,
                      onOpen: open,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: PopIn(
                        index: 6,
                        child: BouncyButton(
                          semanticLabel: l10n.games,
                          onPressed: () => context.go(AppRoutes.games),
                          child: const _GamesButton(),
                        ),
                      ),
                    ),
                  ),
                  // Grown-ups' corner: small and plain on purpose; the parent
                  // gate behind it keeps children out.
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Semantics(
                        button: true,
                        label: l10n.parentArea,
                        excludeSemantics: true,
                        child: IconButton.filledTonal(
                          iconSize: AppSpacing.xl,
                          onPressed: () => context.go(AppRoutes.parent),
                          icon: const Icon(Icons.lock_rounded),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: BouncyButton(
                        semanticLabel: l10n.stickerBook,
                        onPressed: () => context.go(AppRoutes.stickers),
                        child: StickerJar(
                          count: ref.watch(progressProvider).learned.length,
                        ),
                      ),
                    ),
                  ),
                  // More sections on the next page (taps only, no swiping).
                  if (page < pages - 1)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: PopIn(
                          index: 8,
                          child: ArrowButton(
                            direction: ArrowDirection.next,
                            color: AppColors.numbersAccent,
                            onPressed: () => setState(() => _page = page + 1),
                          ),
                        ),
                      ),
                    ),
                  if (page > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ArrowButton(
                          direction: ArrowDirection.previous,
                          color: AppColors.numbersAccent,
                          onPressed: () => setState(() => _page = page - 1),
                        ),
                      ),
                    ),
                  const KidoCorner(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Home tiles that aren't sections.
enum HomeExtra { path, stories, rhymes }

/// Child-facing name of a section, in the app language.
String sectionLabel(AppLocalizations l10n, SectionId id) => switch (id) {
  SectionId.numbers => l10n.sectionNumbers,
  SectionId.abc => l10n.sectionAbc,
  SectionId.hindi => l10n.sectionHindi,
  SectionId.animals => l10n.sectionAnimals,
  SectionId.birds => l10n.sectionBirds,
  SectionId.fruits => l10n.sectionFruits,
  SectionId.vegetables => l10n.sectionVegetables,
  SectionId.colours => l10n.sectionColours,
  SectionId.shapes => l10n.sectionShapes,
  SectionId.vehicles => l10n.sectionVehicles,
  SectionId.body => l10n.sectionBody,
  SectionId.family => l10n.sectionFamily,
  SectionId.days => l10n.sectionDays,
  SectionId.months => l10n.sectionMonths,
  SectionId.opposites => l10n.sectionOpposites,
};

/// Section tiles in two rows of up to five (5 × 96 dp + gaps fits the
/// space between the side columns). Only the selected class's sections.
class _SectionGrid extends StatelessWidget {
  const _SectionGrid({
    required this.sections,
    required this.labelOf,
    required this.imageOf,
    required this.onOpen,
    required this.layout,
    super.key,
  });

  final TileLayout layout;

  /// Tiles in order: a [HomeExtra] or a [SectionId].
  final List<Object> sections;
  final String Function(SectionId) labelOf;
  final String? Function(SectionId) imageOf;
  final void Function(SectionId) onOpen;

  @override
  Widget build(BuildContext context) {
    final perRow = layout.columns;
    final rows = [
      for (var i = 0; i < sections.length; i += perRow)
        sections.sublist(i, math.min(i + perRow, sections.length)),
    ];
    return Builder(
      builder: (context) {
        const gap = AppSpacing.tapGap;
        // Same tile size on every page, even a page with fewer sections.
        final width = layout.tile.width;
        final height = layout.tile.height;
        var index = 0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: gap,
          children: [
            for (final row in rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: gap,
                children: [
                  for (final id in row)
                    SizedBox(
                      width: width,
                      height: height,
                      child: PopIn(
                        index: index++,
                        child: IdleFloat(
                          phase: (index * 0.37) % 1,
                          child: switch (id) {
                            HomeExtra.path => const PathTile(),
                            HomeExtra.stories => const StoriesTile(),
                            HomeExtra.rhymes => const RhymesTile(),
                            final SectionId s => _SectionTile(
                              id: s,
                              label: labelOf(s),
                              image: imageOf(s),
                              onPressed: () => onOpen(s),
                            ),
                            _ => const SizedBox.shrink(),
                          },
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _GamesButton extends StatelessWidget {
  const _GamesButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.minTapTarget,
      height: AppSpacing.minTapTarget,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.gamesAccent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      child: Image.asset('assets/images/games/games.webp'),
    );
  }
}

class _SectionTile extends ConsumerWidget {
  const _SectionTile({
    required this.id,
    required this.label,
    required this.image,
    required this.onPressed,
  });

  final SectionId id;
  final String label;
  final String? image;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = SectionTheme.of(id);
    final progress = ref.watch(sectionProgressProvider(id));
    return BouncyButton(
      semanticLabel: label,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            if (image != null)
              Expanded(
                child: Image.asset(
                  image!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            StarCountBadge(learned: progress.learned, total: progress.total),
          ],
        ),
      ),
    );
  }
}
