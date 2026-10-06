import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../l10n/app_localizations.dart';

/// Home tile for the story shelf.
class StoriesTile extends StatelessWidget {
  const StoriesTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BouncyButton(
      semanticLabel: l10n.stories,
      onPressed: () => context.go(AppRoutes.stories),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.storyAccent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            const Expanded(
              child: FittedBox(
                child: Icon(Icons.auto_stories_rounded, color: AppColors.white),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.stories,
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
