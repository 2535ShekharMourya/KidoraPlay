import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/section.dart';
import '../../features/games/games_screen.dart';
import '../../features/games/quiz_models.dart';
import '../../features/games/quiz_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn_card/learn_card_screen.dart';
import '../../features/numbers/number_rows_screen.dart';
import '../../features/parent/parent_area_screen.dart';
import '../../features/path/path_screen.dart';
import '../../features/play/memory_screen.dart';
import '../../features/play/music_screen.dart';
import '../../features/play/tap_play_screen.dart';
import '../../features/play/toys.dart';
import '../../features/progress/sticker_book_screen.dart';
import '../../features/section_grid/item_grid_screen.dart';
import '../../features/section_grid/section_items.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tracing/trace_screen.dart';
import '../theme/app_tokens.dart';

/// Route paths. Screens are nested so the back button walks up the path:
/// learn card → grid → section → home.
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const stickers = '/home/stickers';
  static const parent = '/home/parent';
  static const games = '/home/games';
  static const path = '/home/path';

  static String game(GameKind kind) => '$games/${kind.name}';

  static String toy(ToyKind kind) => '$games/toy/${kind.name}';

  static String section(SectionId id) => '$home/section/${id.name}';

  static String numberRow(int row) => '${section(SectionId.numbers)}/row/$row';

  static String learn(ItemScope scope, String itemId) {
    final base = scope.row == null
        ? section(scope.section)
        : numberRow(scope.row!);
    return '$base/learn/$itemId';
  }

  /// Finger tracing, on top of the item's learn card.
  static String trace(ItemScope scope, String itemId) =>
      '${learn(scope, itemId)}/trace';
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
      // A fresh screen per item: Next must start the new card's lesson
      // (the router would otherwise reuse the old screen's state).
      key: ValueKey('learn/${state.pathParameters['itemId']}'),
      scope: (section: _sectionOf(state)!, row: row(state)),
      itemId: state.pathParameters['itemId']!,
    ),
  ),
  routes: [
    GoRoute(
      path: 'trace',
      pageBuilder: (context, state) => _playfulPage(
        state,
        TraceScreen(
          key: ValueKey('trace/${state.pathParameters['itemId']}'),
          scope: (section: _sectionOf(state)!, row: row(state)),
          itemId: state.pathParameters['itemId']!,
        ),
      ),
    ),
  ],
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
            path: 'games',
            pageBuilder: (context, state) =>
                _playfulPage(state, const GamesScreen()),
            routes: [
              GoRoute(
                path: 'toy/:toy',
                redirect: (context, state) =>
                    ToyKind.values.asNameMap()[state.pathParameters['toy']] ==
                        null
                    ? AppRoutes.games
                    : null,
                pageBuilder: (context, state) =>
                    _playfulPage(state, switch (ToyKind.values
                        .asNameMap()[state.pathParameters['toy']]!) {
                      ToyKind.tapPlay => const TapPlayScreen(),
                      ToyKind.memory => const MemoryScreen(),
                      ToyKind.music => const MusicScreen(),
                    }),
              ),
              GoRoute(
                path: ':kind',
                redirect: (context, state) =>
                    GameKind.values.asNameMap()[state.pathParameters['kind']] ==
                        null
                    ? AppRoutes.games
                    : null,
                pageBuilder: (context, state) => _playfulPage(
                  state,
                  QuizScreen(
                    key: ValueKey('game/${state.pathParameters['kind']}'),
                    kind: GameKind.values
                        .asNameMap()[state.pathParameters['kind']]!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'path',
            pageBuilder: (context, state) =>
                _playfulPage(state, const PathScreen()),
          ),
          GoRoute(
            path: 'parent',
            pageBuilder: (context, state) =>
                _playfulPage(state, const ParentAreaScreen()),
          ),
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
                    : ItemGridScreen(
                        key: ValueKey('grid/${section.name}'),
                        scope: (section: section, row: null),
                      ),
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
                    key: ValueKey('row/${_rowOf(state)}'),
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
