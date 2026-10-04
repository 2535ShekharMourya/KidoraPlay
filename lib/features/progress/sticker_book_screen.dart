import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../kido/kido_widget.dart';
import '../section_grid/section_items.dart';
import 'progress_controller.dart';

/// The child's sticker book: every item is a sticker, in colour once
/// learned, faded until then. Tapping any sticker says its name.
class StickerBookScreen extends ConsumerStatefulWidget {
  const StickerBookScreen({super.key});

  @override
  ConsumerState<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends ConsumerState<StickerBookScreen> {
  static const _perPage = AppLayout.gridColumns * AppLayout.gridRows;
  SectionId _section = SectionId.values.first;
  int _page = 0;

  void _say(LearningItem item) {
    final languages = ref.read(settingsProvider).language.languages;
    ref.read(audioServiceProvider).playVoiceSequence([
      for (final l in languages) item.voice(l),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(contentCatalogProvider).value;
    final items = ref.watch(scopeItemsProvider((section: _section, row: null)));
    final progress = ref.watch(progressProvider);
    final theme = SectionTheme.of(_section);
    final pages = math.max(1, (items.length / _perPage).ceil());
    final page = _page.clamp(0, pages - 1);
    final pageItems = items.skip(page * _perPage).take(_perPage).toList();

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    // Section tabs.
                    SizedBox(
                      height: AppSpacing.minTapTarget,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final id in SectionId.values)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: _SectionTab(
                                id: id,
                                image: catalog?.section(id)?.image,
                                label: catalog?.section(id)?.titleEn ?? id.name,
                                selected: id == _section,
                                onPressed: () => setState(() {
                                  _section = id;
                                  _page = 0;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = AppSpacing.tapGap;
                          final size = math.max(
                            AppSpacing.minTapTarget,
                            math.min(
                              (constraints.maxWidth - gap * 4) / 5,
                              (constraints.maxHeight - gap) / 2,
                            ),
                          );
                          return Center(
                            child: Wrap(
                              key: ValueKey('$_section-$page'),
                              spacing: gap,
                              runSpacing: gap,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final (i, item) in pageItems.indexed)
                                  SizedBox.square(
                                    dimension: size,
                                    child: PopIn(
                                      index: i,
                                      child: _Sticker(
                                        item: item,
                                        learned: progress.isLearned(item.id),
                                        accent: theme.accent,
                                        onPressed: () => _say(item),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              if (page > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ArrowButton(
                      direction: ArrowDirection.previous,
                      color: theme.accent,
                      onPressed: () => setState(() => _page = page - 1),
                    ),
                  ),
                ),
              if (page < pages - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ArrowButton(
                      direction: ArrowDirection.next,
                      color: theme.accent,
                      onPressed: () => setState(() => _page = page + 1),
                    ),
                  ),
                ),
              const KidoCorner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTab extends ConsumerWidget {
  const _SectionTab({
    required this.id,
    required this.image,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final SectionId id;
  final String? image;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(sectionProgressProvider(id));
    return BouncyButton(
      semanticLabel: '$label ${progress.learned}/${progress.total}',
      sparkle: false,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: AppDurations.highlight,
        width: AppSpacing.minTapTarget * 1.1,
        decoration: BoxDecoration(
          color: selected ? SectionTheme.of(id).accent : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.outline : SectionTheme.of(id).accent,
            width: AppStroke.thick,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          children: [
            if (image != null)
              Expanded(child: Image.asset(image!, fit: BoxFit.contain)),
            _StarCount(
              learned: progress.learned,
              total: progress.total,
              light: selected,
            ),
          ],
        ),
      ),
    );
  }
}

/// "★ 5/26": a section's sticker count.
class StarCountBadge extends StatelessWidget {
  const StarCountBadge({required this.learned, required this.total, super.key});

  final int learned;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      border: Border.all(color: AppColors.outline, width: AppStroke.thin),
    ),
    child: _StarCount(learned: learned, total: total, light: false),
  );
}

class _StarCount extends StatelessWidget {
  const _StarCount({
    required this.learned,
    required this.total,
    required this.light,
  });

  final int learned;
  final int total;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 16,
      height: 1.2,
      color: light ? AppColors.white : AppColors.ink,
    );
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.celebrate, size: 20),
          Text('$learned/$total', style: style),
        ],
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({
    required this.item,
    required this.learned,
    required this.accent,
    required this.onPressed,
  });

  final LearningItem item;
  final bool learned;
  final Color accent;
  final VoidCallback onPressed;

  /// Greyscale for stickers not collected yet.
  static const _grey = ColorFilter.matrix([
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final picture = ItemPicture(
      image: item.image,
      fallbackText: item.wordEn,
      accent: learned ? accent : AppColors.outline.withValues(alpha: 0.3),
    );
    return BouncyButton(
      semanticLabel: item.wordEn,
      sparkle: learned,
      sfx: null,
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: learned
                ? picture
                : Opacity(
                    opacity: 0.35,
                    child: ColorFiltered(colorFilter: _grey, child: picture),
                  ),
          ),
          if (learned)
            const Positioned(
              right: -AppSpacing.xs,
              top: -AppSpacing.xs,
              child: Icon(
                Icons.star_rounded,
                color: AppColors.celebrate,
                size: AppSpacing.xl,
                shadows: [Shadow(color: AppColors.outline, blurRadius: 2)],
              ),
            ),
        ],
      ),
    );
  }
}
