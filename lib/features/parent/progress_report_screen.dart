import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart' show sectionLabel;
import '../progress/progress_controller.dart';

/// For parents (behind the gate): what the child has learned in each
/// section of their class, and a tip on what to practise next. Computed
/// from the stickers on this device only; nothing leaves the phone.
class ProgressReportScreen extends ConsumerWidget {
  const ProgressReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(contentCatalogProvider).value;
    final level = ref.watch(settingsProvider.select((s) => s.level));
    final sections = catalog?.sectionsFor(level) ?? const <Section>[];
    final rows = [
      for (final s in sections)
        (id: s.id, p: ref.watch(sectionProgressProvider(s.id))),
    ];
    final learned = rows.fold<int>(0, (sum, r) => sum + r.p.learned);
    final total = rows.fold<int>(0, (sum, r) => sum + r.p.total);
    final complete = rows
        .where((r) => r.p.total > 0 && r.p.learned == r.p.total)
        .length;

    // Tip: carry on with a section already started (the one with least
    // done), else the first one not started. Encouragement, no deadline.
    final started =
        rows.where((r) => r.p.learned > 0 && r.p.learned < r.p.total).toList()
          ..sort(
            (a, b) =>
                (a.p.learned / a.p.total).compareTo(b.p.learned / b.p.total),
          );
    final notStarted = rows.where((r) => r.p.learned == 0 && r.p.total > 0);
    final next = started.isNotEmpty
        ? started.first.id
        : notStarted.firstOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressReport)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.celebrate,
                    size: AppSpacing.xxl,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.progressSummary(learned, total),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(l10n.progressSectionsDone(complete, rows.length)),
                        if (next != null)
                          Text(l10n.progressNext(sectionLabel(l10n, next))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final r in rows)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: SectionTheme.of(r.id).accent,
                child: r.p.total > 0 && r.p.learned == r.p.total
                    ? const Icon(Icons.check_rounded, color: AppColors.white)
                    : null,
              ),
              title: Text(sectionLabel(l10n, r.id)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: r.p.total == 0 ? 0 : r.p.learned / r.p.total,
                  color: SectionTheme.of(r.id).accent,
                  backgroundColor: AppColors.traceRoad,
                  minHeight: AppSpacing.sm,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
              trailing: Text('${r.p.learned} / ${r.p.total}'),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.progressPrivacy,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
