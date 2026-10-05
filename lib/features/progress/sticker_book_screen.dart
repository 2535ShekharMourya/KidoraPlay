import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/learning_item.dart';
import '../../content/repository/content_catalog.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/paged_tiles.dart';
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
  /// Null: choosing a section. Otherwise: that section's stickers.
  SectionId? _section;

  void _say(LearningItem item) {
    final languages = ref.read(settingsProvider).language.languages;
    ref.read(audioServiceProvider).playVoiceSequence([
      for (final l in languages) item.voice(l),
    ]);
  }

  /// Choose a section: tiles with each section's sticker count.
  Widget _picker(ContentCatalog? catalog) {
    final level = ref.watch(settingsProvider.select((s) => s.level));
    final sections = catalog?.sectionsFor(level) ?? const <Section>[];
    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PagedTiles(
                  count: sections.length,
                  minHeight: AppLayout.sectionTileMinHeight,
                  arrowColor: AppColors.numbersAccent,
                  builder: (context, i, slot) => PopIn(
                    index: slot,
                    child: _SectionTab(
                      id: sections[i].id,
                      image: sections[i].image,
                      label: sections[i].titleEn,
                      selected: false,
                      onPressed: () =>
                          setState(() => _section = sections[i].id),
                    ),
                  ),
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

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(contentCatalogProvider).value;
    final selected = _section;
    if (selected == null) return _picker(catalog);
    final items = ref.watch(scopeItemsProvider((section: selected, row: null)));
    final progress = ref.watch(progressProvider);
    final theme = SectionTheme.of(selected);
    const header = AppSpacing.minTapTarget;

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PagedTiles(
                  key: ValueKey(selected),
                  count: items.length,
                  square: true,
                  arrowColor: theme.accent,
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.sideZone,
                    AppSpacing.sm * 2 + header,
                    AppLayout.sideZone,
                    AppSpacing.sm,
                  ),
                  builder: (context, i, slot) => PopIn(
                    index: slot,
                    child: _Sticker(
                      item: items[i],
                      learned: progress.isLearned(items[i].id),
                      accent: theme.accent,
                      onPressed: () => _say(items[i]),
                    ),
                  ),
                ),
              ),
              // The section's tab on top.
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SizedBox(
                    height: header,
                    width: header,
                    child: _SectionTab(
                      id: selected,
                      image: catalog?.section(selected)?.image,
                      label:
                          catalog?.section(selected)?.titleEn ?? selected.name,
                      selected: true,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                // Back goes to the section choice first.
                child: BigBackButton(
                  onPressed: () => setState(() => _section = null),
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
      badge: item.badge,
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
