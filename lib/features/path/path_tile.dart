import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/beckon.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../l10n/app_localizations.dart';
import 'daily_path.dart';

/// Home's first tile: today's path, with a dot per step. It glows until
/// the path is done (an invitation, never a nag).
class PathTile extends ConsumerWidget {
  const PathTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final path = ref.watch(dailyPathProvider);
    return Beckon(
      active: !path.finished,
      child: BouncyButton(
        semanticLabel: l10n.todayPath,
        onPressed: () => context.go(AppRoutes.path),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pathAccent,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.outline,
              width: AppStroke.thick,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Expanded(
                child: FittedBox(
                  child: Icon(
                    path.finished
                        ? Icons.emoji_events_rounded
                        : Icons.flag_rounded,
                    color: AppColors.white,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.todayPath,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: AppColors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // A dot per step: filled when done.
              FittedBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in path.steps)
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          path.isDone(s)
                              ? Icons.star_rounded
                              : Icons.circle_outlined,
                          size: AppSpacing.md,
                          color: path.isDone(s)
                              ? AppColors.celebrate
                              : AppColors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
