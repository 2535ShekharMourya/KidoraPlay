import 'dart:async';

import 'package:kidoraplay/features/billing/store_gateway.dart';

/// Scriptable stand-in for Google Play.
class FakeStore implements StoreGateway {
  bool available = true;
  Map<String, String> prices = {
    PremiumPlan.monthly.productId: '₹49.00',
    PremiumPlan.yearly.productId: '₹299.00',
    PremiumPlan.lifetime.productId: '₹499.00',
  };

  /// What [ownedProductIds] returns; null means "store unreachable".
  Set<String>? owned = {};
  bool buyStarts = true;

  final bought = <String>[];
  final completed = <String>[];
  int restores = 0;
  final _updates = StreamController<List<StorePurchase>>.broadcast();

  /// Simulates Play reporting a purchase update.
  void emit(StorePurchase purchase) => _updates.add([purchase]);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async => [
    for (final id in ids)
      if (prices[id] case final price?) StoreProduct(id: id, price: price),
  ];

  @override
  Future<bool> buy(String productId) async {
    bought.add(productId);
    return buyStarts;
  }

  @override
  Stream<List<StorePurchase>> get updates => _updates.stream;

  @override
  Future<void> complete(StorePurchase purchase) async =>
      completed.add(purchase.productId);

  @override
  Future<void> restore() async => restores++;

  @override
  Future<Set<String>?> ownedProductIds() async => owned;

  Future<void> dispose() => _updates.close();
}
