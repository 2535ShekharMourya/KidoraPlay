import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/billing/billing_controller.dart';
import 'package:kidoraplay/features/billing/plans_screen.dart';
import 'package:kidoraplay/features/billing/store_gateway.dart';

import '../../helpers/fake_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeStore store;
  late LocalStore local;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: testOverrides(store: local, playStore: store),
    );
    addTearDown(c.dispose);
    // Start listening to purchase updates.
    c.read(billingControllerProvider);
    return c;
  }

  setUp(() {
    store = FakeStore();
    local = LocalStore.inMemory();
  });
  tearDown(() => store.dispose());

  StorePurchase update(PremiumPlan plan, StorePurchaseStatus status) =>
      StorePurchase(
        productId: plan.productId,
        status: status,
        needsCompletion: status == StorePurchaseStatus.purchased,
      );

  group('entitlement', () {
    test('free by default; premium is remembered on the device', () async {
      final c = container();
      expect(c.read(isPremiumProvider), isFalse);
      await c.read(entitlementProvider.notifier).grant(PremiumPlan.yearly);

      final c2 = container();
      expect(c2.read(entitlementProvider), PremiumPlan.yearly);
      expect(c2.read(isPremiumProvider), isTrue);
    });
  });

  group('buying', () {
    test('a completed purchase grants premium and is acknowledged', () async {
      final c = container();
      await c.read(billingControllerProvider.notifier).buy(PremiumPlan.yearly);
      expect(store.bought, [PremiumPlan.yearly.productId]);

      store.emit(update(PremiumPlan.yearly, StorePurchaseStatus.purchased));
      await pumpEventQueue();
      expect(c.read(entitlementProvider), PremiumPlan.yearly);
      expect(c.read(billingControllerProvider).message, BillingMessage.thanks);
      expect(store.completed, [PremiumPlan.yearly.productId]);
    });

    test('pending payment (e.g. UPI) shows waiting, not premium', () async {
      final c = container();
      store.emit(update(PremiumPlan.monthly, StorePurchaseStatus.pending));
      await pumpEventQueue();
      expect(c.read(billingControllerProvider).pending, isTrue);
      expect(c.read(isPremiumProvider), isFalse);

      store.emit(update(PremiumPlan.monthly, StorePurchaseStatus.purchased));
      await pumpEventQueue();
      expect(c.read(billingControllerProvider).pending, isFalse);
      expect(c.read(isPremiumProvider), isTrue);
    });

    test('errors and cancels do not grant premium', () async {
      final c = container();
      store.emit(update(PremiumPlan.lifetime, StorePurchaseStatus.error));
      await pumpEventQueue();
      expect(c.read(billingControllerProvider).message, BillingMessage.failed);
      store.emit(update(PremiumPlan.lifetime, StorePurchaseStatus.canceled));
      await pumpEventQueue();
      expect(c.read(isPremiumProvider), isFalse);
    });

    test('purchases of unknown products are ignored', () async {
      final c = container();
      store.emit(
        const StorePurchase(
          productId: 'something_else',
          status: StorePurchaseStatus.purchased,
        ),
      );
      await pumpEventQueue();
      expect(c.read(isPremiumProvider), isFalse);
    });

    test('if the purchase screen cannot open, say so', () async {
      final c = container();
      store.buyStarts = false;
      await c.read(billingControllerProvider.notifier).buy(PremiumPlan.yearly);
      expect(c.read(billingControllerProvider).message, BillingMessage.failed);
    });
  });

  group('refresh and restore', () {
    test('refresh grants the best owned plan', () async {
      final c = container();
      store.owned = {
        PremiumPlan.monthly.productId,
        PremiumPlan.lifetime.productId,
      };
      await c.read(billingControllerProvider.notifier).refresh();
      expect(c.read(entitlementProvider), PremiumPlan.lifetime);
    });

    test('an ended subscription is removed when Play says so', () async {
      final c = container();
      await c.read(entitlementProvider.notifier).grant(PremiumPlan.monthly);
      store.owned = {};
      await c.read(billingControllerProvider.notifier).refresh();
      expect(c.read(isPremiumProvider), isFalse);
    });

    test('offline keeps the cached premium', () async {
      final c = container();
      await c.read(entitlementProvider.notifier).grant(PremiumPlan.yearly);
      store.owned = null; // store unreachable
      await c.read(billingControllerProvider.notifier).refresh();
      expect(c.read(entitlementProvider), PremiumPlan.yearly);
    });

    test('restore finds a purchase, or says there is none', () async {
      final c = container();
      final billing = c.read(billingControllerProvider.notifier);

      await billing.restore();
      expect(store.restores, 1);
      expect(
        c.read(billingControllerProvider).message,
        BillingMessage.nothingToRestore,
      );

      store.owned = {PremiumPlan.yearly.productId};
      await billing.restore();
      expect(c.read(isPremiumProvider), isTrue);
      expect(
        c.read(billingControllerProvider).message,
        BillingMessage.restored,
      );
    });
  });

  group('PlansScreen', () {
    testWidgets('shows store prices; buy starts the purchase', (tester) async {
      await pumpApp(tester, const PlansScreen(), playStore: store);
      await tester.pumpAndSettle();
      expect(find.text('₹49.00'), findsOneWidget);
      expect(find.text('₹299.00'), findsOneWidget);
      expect(find.text('₹499.00'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('renew automatically'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('renew automatically'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-yearly')),
        -100,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const ValueKey('buy-yearly')));
      await tester.pump();
      expect(store.bought, [PremiumPlan.yearly.productId]);

      store.emit(update(PremiumPlan.yearly, StorePurchaseStatus.purchased));
      await tester.pumpAndSettle();
      expect(find.text('Premium is active. Thank you!'), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-yearly')), findsNothing);
    });

    testWidgets('store unavailable shows a calm message', (tester) async {
      store.available = false;
      await pumpApp(tester, const PlansScreen(), playStore: store);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Google Play is not available'),
        findsOneWidget,
      );
      expect(find.text('Restore purchase'), findsOneWidget);
    });
  });
}
