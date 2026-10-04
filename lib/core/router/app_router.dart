import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/section.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn_card/learn_card_screen.dart';
import '../../features/numbers/number_rows_screen.dart';
import '../../features/progress/sticker_book_screen.dart';
import '../../features/section_grid/item_grid_screen.dart';
import '../../features/section_grid/section_items.dart';
import '../../features/splash/splash_screen.dart';
import '../theme/app_tokens.dart';

/// Route paths. Screens are nested so the back button walks up the path:
/// learn card → grid → section → home.
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const stickers = '/home/stickers';

  static String section(SectionId id) => '$home/section/${id.name}';

  static String numberRow(int row) => '${section(SectionId.numbers)}/row/$row';

  static String learn(ItemScope scope, String itemId) {
    final base = scope.row == null
        ? section(scope.section)
        : numberRow(scope.row!);
    return '$base/learn/$itemId';
  }
}

SectionId? _sectionOf(GoRouterState state) =>
    SectionId.values.asNameMap()[state.pathParameters['sectionId']];

int? _rowOf(GoRouterState state) {
  final row = int.tryParse(state.pathParameters['row'] ?? '');
  return row != null && row >= 1 && row <= 10 ? row : null;
}

/// Scale + fade page transition; instant when reduced motion is on.
CustomTransitionPage<void> _playfulPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppDurations.pageTransition,
      reverseTransitionDuration: AppDurations.pageTransition,
      transitionsBuilder: (context, animation, secondary, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.page,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

GoRoute _learnRoute({required int? Function(GoRouterState) row}) => GoRoute(
  path: 'learn/:itemId',
  pageBuilder: (context, state) => _playfulPage(
    state,
    LearnCardScreen(
      scope: (section: _sectionOf(state)!, row: row(state)),
      itemId: state.pathParameters['itemId']!,
    ),
  ),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) =>
            _playfulPage(state, const HomeScreen()),
        routes: [
          GoRoute(
            path: 'stickers',
            pageBuilder: (context, state) =>
                _playfulPage(state, const StickerBookScreen()),
          ),
          GoRoute(
            path: 'section/:sectionId',
            // Unknown sections (e.g. a stale link) go home.
            redirect: (context, state) =>
                _sectionOf(state) == null ? AppRoutes.home : null,
            pageBuilder: (context, state) {
              final section = _sectionOf(state)!;
              return _playfulPage(
                state,
                section == SectionId.numbers
                    ? const NumberRowsScreen()
                    : ItemGridScreen(scope: (section: section, row: null)),
              );
            },
            routes: [
              GoRoute(
                path: 'row/:row',
                redirect: (context, state) =>
                    _sectionOf(state) != SectionId.numbers ||
                        _rowOf(state) == null
                    ? AppRoutes.home
                    : null,
                pageBuilder: (context, state) => _playfulPage(
                  state,
                  ItemGridScreen(
                    scope: (section: SectionId.numbers, row: _rowOf(state)),
                  ),
                ),
                routes: [_learnRoute(row: _rowOf)],
              ),
              _learnRoute(row: (_) => null),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
