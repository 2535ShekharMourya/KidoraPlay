import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'store_gateway.dart';

/// Google Play Billing via the official in_app_purchase plugin.
class PlayStoreGateway implements StoreGateway {
  final InAppPurchase _iap = InAppPurchase.instance;
  final _details = <String, ProductDetails>{};

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    for (final d in response.productDetails) {
      _details[d.id] = d;
    }
    return [
      for (final d in response.productDetails)
        StoreProduct(id: d.id, price: d.price),
    ];
  }

  @override
  Future<bool> buy(String productId) async {
    final details =
        _details[productId] ??
        (await _iap.queryProductDetails({productId})).productDetails
            .where((d) => d.id == productId)
            .firstOrNull;
    if (details == null) return false;
    // Subscriptions and one-time unlocks both use buyNonConsumable.
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Stream<List<StorePurchase>> get updates => _iap.purchaseStream.map(
    (list) => [
      for (final p in list)
        StorePurchase(
          productId: p.productID,
          status: switch (p.status) {
            PurchaseStatus.pending => StorePurchaseStatus.pending,
            PurchaseStatus.purchased => StorePurchaseStatus.purchased,
            PurchaseStatus.restored => StorePurchaseStatus.restored,
            PurchaseStatus.error => StorePurchaseStatus.error,
            PurchaseStatus.canceled => StorePurchaseStatus.canceled,
          },
          needsCompletion: p.pendingCompletePurchase,
          raw: p,
        ),
    ],
  );

  @override
  Future<void> complete(StorePurchase purchase) async {
    if (purchase.raw case final PurchaseDetails details) {
      await _iap.completePurchase(details);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<Set<String>?> ownedProductIds() async {
    if (!await _iap.isAvailable()) return null;
    final android = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await android.queryPastPurchases();
    if (response.error != null) return null;
    return {
      for (final p in response.pastPurchases)
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored)
          p.productID,
    };
  }
}
