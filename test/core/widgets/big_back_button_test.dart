import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/big_back_button.dart';
import 'package:kidoraplay/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('pops back to the previous screen', (tester) async {
    useLandscapePhone(tester);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('first')),
        GoRoute(
          path: '/second',
          builder: (_, _) => const Scaffold(
            body: Align(alignment: Alignment.topLeft, child: BigBackButton()),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(LocalStore.inMemory()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    unawaited(router.push('/second'));
    await tester.pumpAndSettle();
    expect(find.byType(BigBackButton), findsOneWidget);

    // Big and not flush against the screen edge.
    final rect = tester.getRect(find.byIcon(Icons.arrow_back_rounded));
    expect(rect.left, greaterThanOrEqualTo(AppSpacing.md));
    expect(rect.top, greaterThanOrEqualTo(AppSpacing.md));
    final button = tester.getSize(
      find.descendant(
        of: find.byType(BigBackButton),
        matching: find.byType(Container),
      ),
    );
    expect(button.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));

    await tester.tap(find.byType(BigBackButton));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
  });

  testWidgets('custom onPressed is used', (tester) async {
    var pressed = false;
    await pumpApp(tester, BigBackButton(onPressed: () => pressed = true));
    await tester.tap(find.byType(BigBackButton));
    expect(pressed, isTrue);
    await tester.pumpAndSettle();
  });
}
