import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/section.dart';
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
import '../section_grid/section_items.dart';

/// Numbers grouped in rows of ten: 1–10, 11–20 … 91–100. The child taps a
/// row, then a number. Nursery sees only 1–20.
class NumberRowsScreen extends ConsumerWidget {
  const NumberRowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(numberRowsProvider);
    final accent = SectionTheme.of(SectionId.numbers).accent;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SectionBackground(
        section: SectionId.numbers,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.md,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const cols = AppLayout.gridColumns;
                    const gap = AppSpacing.tapGap;
                    final width = (constraints.maxWidth - gap * (cols - 1)) /
                        cols;
                    final height = (constraints.maxHeight - gap) / 2;
                    return Center(
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (i, row) in rows.indexed)
                            SizedBox(
                              width: width,
                              height: height.clamp(
                                AppSpacing.minTapTarget,
                                width * 1.3,
                              ),
                              child: PopIn(
                                index: i,
                                child: IdleFloat(
                                  phase: (i * 0.37) % 1,
                                  child: BouncyButton(
                                    semanticLabel: l10n.numberRow(
                                      row * 10 - 9,
                                      row * 10,
                                    ),
                                    onPressed: () =>
                                        context.go(AppRoutes.numberRow(row)),
                                    child: _RowTile(row: row, accent: accent),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Align(
                alignment: Alignment.topLeft,
                child: BigBackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.accent});

  final int row;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .headlineMedium
        ?.copyWith(color: AppColors.white, height: 1);
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${row * 10 - 9}', style: style),
            Text('–', style: style),
            Text('${row * 10}', style: style),
          ],
        ),
      ),
    );
  }
}
