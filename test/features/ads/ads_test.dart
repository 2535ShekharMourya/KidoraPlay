import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_theme.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/ads/ad_break_screen.dart';
import 'package:kidoraplay/features/ads/ad_gateway.dart';
import 'package:kidoraplay/features/ads/ad_manager.dart';
import 'package:kidoraplay/features/ads/ad_rules.dart';
import 'package:kidoraplay/features/billing/billing_controller.dart';
import 'package:kidoraplay/features/billing/store_gateway.dart';
import 'package:kidoraplay/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

class FakeAdGateway implements AdGateway {
  final log = <String>[];
  bool fill = true;
  bool _loaded = false;

  @override
  Future<void> initialize() async => log.add('init');

  @override
  Future<void> preload() async {
    log.add('preload');
    _loaded = fill;
  }

  @override
  bool get hasInterstitial => _loaded;

  @override
  Future<void> show() async {
    log.add('show');
    _loaded = false;
  }

  @override
  void discard() {
    log.add('discard');
    _loaded = false;
  }
}

void main() {
  group('rules', () {
    final start = DateTime(2026, 10, 5, 10);

    test('no ad in the first 3 minutes of a session', () {
      expect(
        AdRules.canShow(
          premium: false,
          sessionStart: start,
          now: start.add(const Duration(minutes: 2, seconds: 59)),
        ),
        isFalse,
      );
      expect(
        AdRules.canShow(
          premium: false,
          sessionStart: start,
          now: start.add(const Duration(minutes: 3)),
        ),
        isTrue,
      );
    });

    test('at least 4 minutes between ads', () {
      final last = start.add(const Duration(minutes: 5));
      bool at(Duration d) => AdRules.canShow(
        premium: false,
        sessionStart: start,
        lastShown: last,
        now: last.add(d),
      );
      expect(at(const Duration(minutes: 3, seconds: 59)), isFalse);
      expect(at(const Duration(minutes: 4)), isTrue);
    });

    test('premium never sees an ad', () {
      expect(
        AdRules.canShow(
          premium: true,
          sessionStart: start,
          now: start.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
    });
  });

  group('manager', () {
    late FakeAdGateway ads;
    late DateTime now;

    Future<ProviderContainer> pumpHost(
      WidgetTester tester, {
      bool premium = false,
    }) async {
      useLandscapePhone(tester);
      ads = FakeAdGateway();
      now = DateTime(2026, 10, 5, 10);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testOverrides(
              ads: ads,
              store: LocalStore.inMemory({
                'settings.language': 'en',
                if (premium)
                  'billing.premium_product': PremiumPlan.lifetime.productId,
              }),
            ),
            adClockProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      return ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    }

    Future<bool> offerBreak(WidgetTester tester, ProviderContainer c) async {
      final context = tester.element(find.byType(Scaffold));
      var result = false;
      var done = false;
      unawaited(
        c.read(adManagerProvider).maybeShowBreak(context, reason: 'test').then((
          r,
        ) {
          result = r;
          done = true;
        }),
      );
      for (var i = 0; i < 40 && !done; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return result;
    }

    testWidgets('premium users never start the ad SDK', (tester) async {
      final c = await pumpHost(tester, premium: true);
      await c.read(adManagerProvider).start();
      expect(ads.log, isEmpty);
      now = now.add(const Duration(minutes: 10));
      expect(await offerBreak(tester, c), isFalse);
      expect(find.byType(AdBreakScreen), findsNothing);
    });

    testWidgets('child-directed SDK starts, then the first ad loads', (
      tester,
    ) async {
      final c = await pumpHost(tester);
      await c.read(adManagerProvider).start();
      expect(ads.log, ['init', 'preload']);
    });

    testWidgets('too early in the session: no break, no ad', (tester) async {
      final c = await pumpHost(tester);
      await c.read(adManagerProvider).start();
      now = now.add(const Duration(minutes: 2));
      expect(await offerBreak(tester, c), isFalse);
      expect(find.byType(AdBreakScreen), findsNothing);
      expect(ads.log, isNot(contains('show')));
    });

    testWidgets('Kido\'s break screen first, then the ad; then 4 min gap', (
      tester,
    ) async {
      final c = await pumpHost(tester);
      await c.read(adManagerProvider).start();
      now = now.add(const Duration(minutes: 3));

      final context = tester.element(find.byType(Scaffold));
      final shown = c
          .read(adManagerProvider)
          .maybeShowBreak(context, reason: 'section_done');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The break screen is up and the ad has not started yet.
      expect(find.byType(AdBreakScreen), findsOneWidget);
      expect(find.text('Kido is taking a little break 🐘'), findsOneWidget);
      expect(ads.log, isNot(contains('show')));
      // Nothing on it can be tapped.
      expect(find.byType(InkWell), findsNothing);

      await tester.pump(AppDurations.adBreak);
      await tester.pump(const Duration(milliseconds: 500));
      expect(await shown, isTrue);
      expect(ads.log.where((e) => e == 'show'), hasLength(1));
      expect(find.byType(AdBreakScreen), findsNothing);
      // The next ad is loaded right away.
      expect(ads.log.last, 'preload');

      now = now.add(const Duration(minutes: 2));
      expect(await offerBreak(tester, c), isFalse);
      now = now.add(const Duration(minutes: 2));
      expect(await offerBreak(tester, c), isTrue);
      expect(ads.log.where((e) => e == 'show'), hasLength(2));
    });

    testWidgets('no fill: the child just carries on', (tester) async {
      final c = await pumpHost(tester);
      ads.fill = false;
      await c.read(adManagerProvider).start();
      now = now.add(const Duration(minutes: 5));
      expect(await offerBreak(tester, c), isFalse);
      expect(find.byType(AdBreakScreen), findsNothing);
      expect(ads.log.last, 'preload');
    });

    testWidgets('buying premium drops the loaded ad', (tester) async {
      final c = await pumpHost(tester);
      final manager = c.read(adManagerProvider);
      await manager.start();
      await c.read(entitlementProvider.notifier).grant(PremiumPlan.monthly);
      now = now.add(const Duration(minutes: 10));
      expect(await offerBreak(tester, c), isFalse);
      expect(ads.log, contains('discard'));
      expect(ads.log, isNot(contains('show')));
      expect(find.byType(AdBreakScreen), findsNothing);
    });
  });

  test('the manifest removes the advertising ID permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      contains('android:name="com.google.android.gms.permission.AD_ID"'),
    );
    for (final permission in [
      'com.google.android.gms.permission.AD_ID',
      'android.permission.ACCESS_ADSERVICES_AD_ID',
      'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
      'android.permission.ACCESS_ADSERVICES_TOPICS',
    ]) {
      expect(
        manifest,
        matches(
          RegExp(
            'android:name="${RegExp.escape(permission)}"'
            r'\s*tools:node="remove"',
          ),
        ),
        reason: permission,
      );
    }
    expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
  });
}
