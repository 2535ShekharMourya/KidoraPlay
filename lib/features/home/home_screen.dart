import 'package:flutter/material.dart';

import '../../content/models/section.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../l10n/app_localizations.dart';

/// Section menu. Placeholder for step 1; tiles get bounce, sound and
/// navigation in steps 3–5.
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              for (final id in SectionId.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.tapGap / 2),
                    child: _SectionTile(id: id, label: labels[id]!),
                  ),
                ),
            ],
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
    return Semantics(
      button: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTapTarget,
          minHeight: AppSpacing.minTapTarget,
        ),
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
