import 'package:flutter/foundation.dart';

/// Kidoraplay's paid plans. Prices are set in Google Play Console.
enum PremiumPlan {
  monthly('kidora_premium_monthly', isSubscription: true),
  yearly('kidora_premium_yearly', isSubscription: true),
  lifetime('kidora_premium_lifetime', isSubscription: false);

  const PremiumPlan(this.productId, {required this.isSubscription});

  final String productId;
  final bool isSubscription;

  static final Set<String> productIds = {for (final p in values) p.productId};

  static PremiumPlan? byProductId(String id) {
    for (final p in values) {
      if (p.productId == id) return p;
    }
    return null;
  }
}

/// A product as the store shows it (localised title and price).
@immutable
class StoreProduct {
  const StoreProduct({required this.id, required this.price});

  final String id;

  /// Formatted for the user's locale, e.g. "₹299.00".
  final String price;
}

enum StorePurchaseStatus { pending, purchased, restored, error, canceled }

/// A purchase update from the store.
@immutable
class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
    this.raw,
  });

  final String productId;
  final StorePurchaseStatus status;

  /// Must be acknowledged with [StoreGateway.complete], or Google Play
  /// refunds it after three days.
  final bool needsCompletion;

  /// The platform object, for [StoreGateway.complete].
  final Object? raw;
}

/// The app store, behind an interface so billing logic can be tested
/// without Google Play.
abstract interface class StoreGateway {
  Future<bool> isAvailable();

  /// Products that exist in the store, with prices.
  Future<List<StoreProduct>> products(Set<String> ids);

  /// Starts a purchase; the result arrives on [updates]. Returns false if
  /// the purchase flow could not be started.
  Future<bool> buy(String productId);

  Stream<List<StorePurchase>> get updates;

  Future<void> complete(StorePurchase purchase);

  /// Re-delivers past purchases on [updates].
  Future<void> restore();

  /// Product ids the user owns right now, or null if the store could not
  /// be asked (offline, Play services missing).
  Future<Set<String>?> ownedProductIds();
}
