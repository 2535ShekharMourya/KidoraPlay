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
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/section_background.dart';
import '../../core/widgets/wiggle.dart';
import '../numbers/place_value_view.dart';
import '../section_grid/section_items.dart';
import 'learn_card_controller.dart';
import 'spelling_strip.dart';

/// Reusable learn card for any item: big picture, the word (English and/or
/// Hindi), place value for numbers, and the spelling strip. Opens straight
/// into the lesson; tapping the picture plays it again.
class LearnCardScreen extends ConsumerStatefulWidget {
  const LearnCardScreen({required this.scope, required this.itemId, super.key});

  final ItemScope scope;
  final String itemId;

  @override
  ConsumerState<LearnCardScreen> createState() => _LearnCardScreenState();
}

class _LearnCardScreenState extends ConsumerState<LearnCardScreen> {
  final _burst = BurstController();

  LearnCardController get _controller =>
      ref.read(learnCardControllerProvider(widget.itemId).notifier);

  @override
  void initState() {
    super.initState();
    // Start after the page transition begins so audio and visuals line up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.playLesson();
    });
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(scopeItemsProvider(widget.scope));
    final index = items.indexWhere((i) => i.id == widget.itemId);
    final theme = SectionTheme.of(widget.scope.section);

    ref.listen(
      learnCardControllerProvider(widget.itemId).select((s) => s.celebrations),
      (previous, next) => _burst.fire(),
    );

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
    final state = ref.watch(learnCardControllerProvider(widget.itemId));
    final languages = ref.watch(
      settingsProvider.select((s) => s.language.languages),
    );

    void goTo(LearningItem other) =>
        context.go(AppRoutes.learn(widget.scope, other.id));

    return Scaffold(
      body: SectionBackground(
        section: widget.scope.section,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppLayout.sideZone,
                  right: AppLayout.sideZone,
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
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
                                child: ParticleBurst(
                                  controller: _burst,
                                  child: IdleFloat(
                                    child: Wiggle(
                                      active: state.reacting,
                                      child: BouncyButton(
                                        semanticLabel: item.wordEn,
                                        sfx: null,
                                        onPressed: _controller.playLesson,
                                        child: ItemPicture(
                                          image: item.image,
                                          fallbackText: item.wordEn,
                                          accent: theme.accent,
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
                            child: _WordPanel(
                              item: item,
                              languages: languages,
                              section: widget.scope.section,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: SpellingStrip(
                        tiles: item.spelling,
                        revealed: state.revealed,
                        highlighted: state.highlighted,
                        accent: theme.accent,
                        onTapLetter: _controller.tapLetter,
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
                    child: ArrowButton(
                      direction: ArrowDirection.next,
                      color: theme.accent,
                      onPressed: () => goTo(items[index + 1]),
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

class _WordPanel extends StatelessWidget {
  const _WordPanel({
    required this.item,
    required this.languages,
    required this.section,
  });

  final LearningItem item;
  final List<ContentLanguage> languages;
  final SectionId section;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final number = item.number;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final lang in languages)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.word(lang),
              style: lang == ContentLanguage.en
                  ? text.displayLarge?.copyWith(fontSize: 48)
                  : text.headlineMedium?.copyWith(fontSize: 40),
            ),
          ),
        if (number != null && number >= 10) ...[
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
