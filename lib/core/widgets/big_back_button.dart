import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'bouncy_button.dart';

/// Big, always-visible back button. Place it top-left; it carries its own
/// margin so it never sits flush against the screen edge.
class BigBackButton extends StatelessWidget {
  const BigBackButton({this.onPressed, super.key});

  /// Defaults to popping the route, or going Home if there is nothing to pop.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: BouncyButton(
        semanticLabel: AppLocalizations.of(context).back,
        sparkle: false,
        onPressed: onPressed ??
            () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.home),
        child: Container(
          width: AppSpacing.minTapTarget,
          height: AppSpacing.minTapTarget,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outline,
              width: AppStroke.thick,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: AppSpacing.minTapTarget * 0.55,
            color: AppColors.outline,
          ),
        ),
      ),
    );
  }
}
