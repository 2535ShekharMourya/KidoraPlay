import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/learning_item.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/arrow_button.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../kido/kido_memory.dart';
import '../kido/kido_widget.dart';
import 'section_items.dart';

/// Reusable picture grid for any section (or one row of numbers).
/// Shows 10 cards per page; more pages are reached with big arrows.
class ItemGridScreen extends ConsumerStatefulWidget {
  const ItemGridScreen({required this.scope, super.key});

  final ItemScope scope;

  @override
  ConsumerState<ItemGridScreen> createState() => _ItemGridScreenState();
}

class _ItemGridScreenState extends ConsumerState<ItemGridScreen> {
  static const _perPage = AppLayout.gridColumns * AppLayout.gridRows;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // A row of numbers is inside the Numbers visit already.
    if (widget.scope.row == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => enterSection(ref, widget.scope.section),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(scopeItemsProvider(widget.scope));
    final theme = SectionTheme.of(widget.scope.section);
    final pages = math.max(1, (items.length / _perPage).ceil());
    final page = _page.clamp(0, pages - 1);
    final pageItems = items.skip(page * _perPage).take(_perPage).toList();

    return Scaffold(
      body: SectionBackground(
        section: widget.scope.section,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.md,
                ),
                child: _Grid(
                  // A new key per page replays the pop-in animation.
                  key: ValueKey(page),
                  items: pageItems,
                  accent: theme.accent,
                  onTap: (item) =>
                      context.go(AppRoutes.learn(widget.scope, item.id)),
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              const KidoCorner(),
              if (page > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ArrowButton(
                      direction: ArrowDirection.previous,
                      color: theme.accent,
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
                      color: theme.accent,
                      onPressed: () => setState(() => _page = page + 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.items,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final List<LearningItem> items;
  final Color accent;
  final void Function(LearningItem) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = AppLayout.gridColumns;
        const rows = AppLayout.gridRows;
        const gap = AppSpacing.tapGap;
        final size = math.max(
          AppSpacing.minTapTarget,
          math.min(
            (constraints.maxWidth - gap * (cols - 1)) / cols,
            (constraints.maxHeight - gap * (rows - 1)) / rows,
          ),
        );

        return Center(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            alignment: WrapAlignment.center,
            children: [
              for (final (i, item) in items.indexed)
                SizedBox.square(
                  dimension: size,
                  child: PopIn(
                    index: i,
                    child: IdleFloat(
                      phase: (i * 0.37) % 1,
                      child: BouncyButton(
                        semanticLabel: item.wordEn,
                        onPressed: () => onTap(item),
                        child: ItemPicture(
                          image: item.image,
                          fallbackText: item.wordEn,
                          accent: accent,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
