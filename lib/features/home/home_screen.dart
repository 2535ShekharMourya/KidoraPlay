import 'package:flutter/material.dart';

import '../../content/models/section.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';

/// Section menu. Tiles bounce and sparkle; navigation arrives in step 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      SectionId.numbers: l10n.sectionNumbers,
      SectionId.abc: l10n.sectionAbc,
      SectionId.animals: l10n.sectionAnimals,
      SectionId.birds: l10n.sectionBirds,
    };

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Row(
              children: [
                for (final (i, id) in SectionId.values.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.tapGap / 2),
                      child: PopIn(
                        index: i,
                        child: IdleFloat(
                          phase: i / SectionId.values.length,
                          child: _SectionTile(id: id, label: labels[id]!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.id, required this.label});

  final SectionId id;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = SectionTheme.of(id);
    return BouncyButton(
      semanticLabel: label,
      onPressed: () {},
      child: Container(
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.white),
            ),
          ),
        ),
      ),
    );
  }
}
