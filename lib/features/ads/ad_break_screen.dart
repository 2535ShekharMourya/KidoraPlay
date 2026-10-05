import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_widget.dart';

/// Shows [AdBreakScreen] over everything and completes when it closes.
Future<void> showAdBreak(BuildContext context) => showGeneralDialog<void>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: false,
  transitionDuration: AppDurations.pageTransition,
  pageBuilder: (context, _, _) => const AdBreakScreen(),
);

/// "Kido is taking a break 🐘": a calm, non-interactive pause before an
/// ad, so an ad never appears straight after a child's tap. Closes itself.
class AdBreakScreen extends StatefulWidget {
  const AdBreakScreen({super.key});

  @override
  State<AdBreakScreen> createState() => _AdBreakScreenState();
}

class _AdBreakScreenState extends State<AdBreakScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppDurations.adBreak, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // No buttons, and back does nothing: nothing here can be tapped.
    return PopScope(
      canPop: false,
      child: AbsorbPointer(
        child: Material(
          color: AppColors.homeSky,
          child: SectionBackground(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: AppLayout.splashKido * AppLayout.kidoAspect,
                    height: AppLayout.splashKido,
                    child: KidoWidget(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.adBreak,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
