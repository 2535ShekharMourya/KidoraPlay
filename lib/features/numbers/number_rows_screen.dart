import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/section.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../core/widgets/tile_layout.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_memory.dart';
import '../kido/kido_widget.dart';
import '../section_grid/section_items.dart';

/// Numbers grouped in rows of ten: 1–10, 11–20 … 91–100. The child taps a
/// row, then a number. Nursery sees only 1–20.
class NumberRowsScreen extends ConsumerStatefulWidget {
  const NumberRowsScreen({super.key});

  @override
  ConsumerState<NumberRowsScreen> createState() => _NumberRowsScreenState();
}

class _NumberRowsScreenState extends ConsumerState<NumberRowsScreen> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => enterSection(ref, SectionId.numbers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(numberRowsProvider);
    final accent = SectionTheme.of(SectionId.numbers).accent;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SectionBackground(
        section: SectionId.numbers,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Up to two rows of five; on small phones fewer per page.
              final layout = TileLayout.fit(
                Size(
                  constraints.maxWidth - AppLayout.sideZone * 2,
                  constraints.maxHeight - AppSpacing.md * 2,
                ),
              );
              final pages = layout.pagesFor(rows.length);
              final page = _page.clamp(0, pages - 1);
              final shown = rows
                  .skip(page * layout.perPage)
                  .take(layout.perPage)
                  .toList();
              const gap = AppSpacing.tapGap;
              final cols = layout.columns;
              // Tall enough for "11 – 20", never taller than needed.
              final tile = Size(
                layout.tile.width,
                math.min(layout.tile.height, layout.tile.width * 1.3),
              );
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.sideZone,
                      vertical: AppSpacing.md,
                    ),
                    child: Center(
                      child: Column(
                        key: ValueKey(page),
                        mainAxisSize: MainAxisSize.min,
                        spacing: gap,
                        children: [
                          for (var r = 0; r * cols < shown.length; r++)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: gap,
                              children: [
                                for (final (k, row)
                                    in shown.skip(r * cols).take(cols).indexed)
                                  SizedBox.fromSize(
                                    size: tile,
                                    child: PopIn(
                                      index: r * cols + k,
                                      child: IdleFloat(
                                        phase: ((r * cols + k) * 0.37) % 1,
                                        child: BouncyButton(
                                          semanticLabel: l10n.numberRow(
                                            row * 10 - 9,
                                            row * 10,
                                          ),
                                          onPressed: () => context.go(
                                            AppRoutes.numberRow(row),
                                          ),
                                          child: _RowTile(
                                            row: row,
                                            accent: accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: BigBackButton(),
                  ),
                  const KidoCorner(),
                  if (page > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ArrowButton(
                          direction: ArrowDirection.previous,
                          color: accent,
                          onPressed: () => setState(() => _page = page - 1),
                        ),
                      ),
                    ),
                  if (page < pages - 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ArrowButton(
                          direction: ArrowDirection.next,
                          color: accent,
                          onPressed: () => setState(() => _page = page + 1),
                        ),
                      ),
                    ),
                ],
              );
            },
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
    final style = Theme.of(context).textTheme.headlineMedium
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
