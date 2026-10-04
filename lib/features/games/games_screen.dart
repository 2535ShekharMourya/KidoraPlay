import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_widget.dart';
import 'quiz_models.dart';

/// Picks a practice game.
class GamesScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.gamesBg,
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.xxl,
                ),
                child: Row(
                  children: [
                    for (final (i, kind) in GameKind.values.indexed)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.tapGap / 2),
                          child: PopIn(
                            index: i,
                            child: IdleFloat(
                              phase: i / GameKind.values.length,
                              child: BouncyButton(
                                semanticLabel: labelFor(l10n, kind),
                                onPressed: () =>
                                    context.go(AppRoutes.game(kind)),
                                child: _GameCard(
                                  image: imageFor(kind),
                                  label: labelFor(l10n, kind),
                                  color: SectionTheme.of(kind.theme).accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
