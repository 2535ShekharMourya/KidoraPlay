import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import 'play_store_gateway.dart';
import 'store_gateway.dart';

/// Whether this device has premium. Cached locally so the app knows
/// offline, and before deciding whether to start ads at all.
class EntitlementNotifier extends Notifier<PremiumPlan?> {
  static const _key = 'billing.premium_product';

  @override
  PremiumPlan? build() {
    final id = ref.watch(localStoreProvider).getString(_key);
    return id == null ? null : PremiumPlan.byProductId(id);
  }

  Future<void> grant(PremiumPlan plan) async {
    state = plan;
    await ref.read(localStoreProvider).setString(_key, plan.productId);
  }

  Future<void> revoke() async {
    state = null;
    await ref.read(localStoreProvider).setString(_key, '');
  }
}

final entitlementProvider = NotifierProvider<EntitlementNotifier, PremiumPlan?>(
  EntitlementNotifier.new,
);

/// True for premium users: no ads, everything unlocked.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(entitlementProvider) != null,
);

/// Messages for the plans screen (parents only).
enum BillingMessage { none, thanks, restored, nothingToRestore, failed }

@immutable
class BillingState {
  const BillingState({
    this.available,
    this.products = const {},
    this.pending = false,
    this.message = BillingMessage.none,
  });

  /// Null while checking the store.
  final bool? available;

  /// Store products by plan, with localised prices.
  final Map<PremiumPlan, StoreProduct> products;

  /// A payment is in progress (e.g. waiting for UPI approval).
  final bool pending;
  final BillingMessage message;

  BillingState copyWith({
    bool? available,
    Map<PremiumPlan, StoreProduct>? products,
    bool? pending,
    BillingMessage? message,
  }) => BillingState(
    available: available ?? this.available,
    products: products ?? this.products,
    pending: pending ?? this.pending,
    message: message ?? this.message,
  );
}

/// Buying, restoring and refreshing premium. Purchases are acknowledged
/// so Google Play keeps them. There is no account or server: the
/// entitlement lives on the device and is re-checked with Play.
class BillingController extends Notifier<BillingState> {
  StoreGateway get _store => ref.read(storeGatewayProvider);

  @override
  BillingState build() {
    final sub = ref
        .read(storeGatewayProvider)
        .updates
        .listen(_onUpdates, onError: (Object _) {});
    ref.onDispose(sub.cancel);
    return const BillingState();
  }

  /// Loads plans and prices for the plans screen.
  Future<void> load() async {
    try {
      final available = await _store.isAvailable();
      if (!available) {
        state = state.copyWith(available: false);
        return;
      }
      final products = await _store.products(PremiumPlan.productIds);
      state = state.copyWith(
        available: true,
        products: {
          for (final p in products) ?PremiumPlan.byProductId(p.id): p,
        },
      );
    } catch (e) {
      debugPrint('Billing load failed: $e');
      state = state.copyWith(available: false);
    }
  }

  Future<void> buy(PremiumPlan plan) async {
    state = state.copyWith(message: BillingMessage.none);
    try {
      final started = await _store.buy(plan.productId);
      if (!started) state = state.copyWith(message: BillingMessage.failed);
    } catch (e) {
      debugPrint('Billing buy failed: $e');
      state = state.copyWith(message: BillingMessage.failed);
    }
  }

  /// "Restore purchase": asks Play for past purchases.
  Future<void> restore() async {
    state = state.copyWith(message: BillingMessage.none);
    try {
      await _store.restore();
    } catch (e) {
      debugPrint('Billing restore failed: $e');
    }
    final owned = await refresh();
    if (owned == null) {
      state = state.copyWith(message: BillingMessage.failed);
    } else if (ref.read(entitlementProvider) == null) {
      state = state.copyWith(message: BillingMessage.nothingToRestore);
    } else {
      state = state.copyWith(message: BillingMessage.restored);
    }
  }

  /// Re-checks ownership with the store (on launch and after restore).
  /// Premium is removed only when the store answers and no plan is owned
  /// (e.g. a cancelled subscription ran out); offline keeps the cache.
  Future<Set<String>?> refresh() async {
    Set<String>? owned;
    try {
      owned = await _store.ownedProductIds();
    } catch (e) {
      debugPrint('Billing refresh failed: $e');
    }
    if (owned == null) return null;
    final plan = _bestPlan(owned);
    final entitlement = ref.read(entitlementProvider.notifier);
    if (plan != null) {
      await entitlement.grant(plan);
    } else if (ref.read(entitlementProvider) != null) {
      await entitlement.revoke();
    }
    return owned;
  }

  Future<void> _onUpdates(List<StorePurchase> purchases) async {
    for (final p in purchases) {
      final plan = PremiumPlan.byProductId(p.productId);
      if (plan == null) continue;
      switch (p.status) {
        case StorePurchaseStatus.pending:
          state = state.copyWith(pending: true);
        case StorePurchaseStatus.purchased || StorePurchaseStatus.restored:
          await ref.read(entitlementProvider.notifier).grant(plan);
          state = state.copyWith(
            pending: false,
            message: p.status == StorePurchaseStatus.purchased
                ? BillingMessage.thanks
                : BillingMessage.restored,
          );
        case StorePurchaseStatus.error:
          state = state.copyWith(
            pending: false,
            message: BillingMessage.failed,
          );
        case StorePurchaseStatus.canceled:
          state = state.copyWith(pending: false);
      }
      if (p.needsCompletion) {
        try {
          await _store.complete(p);
        } catch (e) {
          debugPrint('Billing complete failed: $e');
        }
      }
    }
  }

  /// Lifetime beats yearly beats monthly if several are owned.
  static PremiumPlan? _bestPlan(Set<String> owned) {
    for (final plan in [
      PremiumPlan.lifetime,
      PremiumPlan.yearly,
      PremiumPlan.monthly,
    ]) {
      if (owned.contains(plan.productId)) return plan;
    }
    return null;
  }
}

/// The real store. Tests override this with a fake.
final storeGatewayProvider = Provider<StoreGateway>(
  (ref) => PlayStoreGateway(),
);

final billingControllerProvider =
    NotifierProvider<BillingController, BillingState>(BillingController.new);
