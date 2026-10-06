import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/level.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/paged_tiles.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_widget.dart';
import '../play/toys.dart';
import 'quiz_models.dart';

/// Picks a practice game.
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  static String imageFor(GameKind kind) => switch (kind) {
    GameKind.findIt => 'assets/images/games/find_it.webp',
    GameKind.whoSays => 'assets/images/games/who_says.webp',
    GameKind.countIt => 'assets/images/games/count_it.webp',
    GameKind.letters => 'assets/images/games/letters.webp',
  };

  static String labelFor(AppLocalizations l10n, GameKind kind) =>
      switch (kind) {
        GameKind.findIt => l10n.gameFindIt,
        GameKind.whoSays => l10n.gameWhoSays,
        GameKind.countIt => l10n.gameCount,
        GameKind.letters => l10n.gameLetters,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final level = ref.watch(settingsProvider.select((s) => s.level));
    final activities = [
      for (final toy in ToyKind.values)
        (
          label: toy.label(l10n),
          image: toy.image,
          color: AppColors.toyAccent,
          route: AppRoutes.toy(toy),
        ),
      for (final kind in GameKind.values)
        // Letters come later than the baby class.
        if (kind != GameKind.letters || level != Level.baby)
          (
            label: labelFor(l10n, kind),
            image: imageFor(kind),
            color: SectionTheme.of(kind.theme).accent,
            route: AppRoutes.game(kind),
          ),
    ];
    return Scaffold(
      backgroundColor: AppColors.gamesBg,
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Toys first (the youngest can play them), then quiz games.
              Positioned.fill(
                child: PagedTiles(
                  count: activities.length,
                  maxColumns: 4,
                  minHeight: AppLayout.sectionTileMinHeight,
                  arrowColor: AppColors.numbersAccent,
                  builder: (context, i, slot) {
                    final a = activities[i];
                    return PopIn(
                      index: slot,
                      child: IdleFloat(
                        phase: i / activities.length,
                        child: BouncyButton(
                          semanticLabel: a.label,
                          onPressed: () => context.go(a.route),
                          child: _GameCard(
                            image: a.image,
                            label: a.label,
                            color: a.color,
                          ),
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

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.image,
    required this.label,
    required this.color,
  });

  final String image;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Expanded(child: Image.asset(image, fit: BoxFit.contain)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
