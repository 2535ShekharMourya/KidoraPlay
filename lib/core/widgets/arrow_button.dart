import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../audio/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'bouncy_button.dart';

enum ArrowDirection { previous, next }

/// Big round next/previous button for paging and moving between items.
class ArrowButton extends StatelessWidget {
  const ArrowButton({
    required this.direction,
    required this.onPressed,
    required this.color,
    super.key,
  });

  final ArrowDirection direction;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = direction == ArrowDirection.next;
    return BouncyButton(
      semanticLabel: next ? l10n.next : l10n.previous,
      sparkle: false,
      sfx: Sfx.whoosh,
      onPressed: onPressed,
      child: Container(
        width: AppSpacing.minTapTarget,
        height: AppSpacing.minTapTarget,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        child: Icon(
          next ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          size: AppSpacing.minTapTarget * 0.55,
          color: AppColors.white,
        ),
      ),
    );
  }
}
