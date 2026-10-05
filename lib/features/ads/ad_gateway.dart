import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// The ad SDK, behind an interface so the rules can be tested without it.
abstract interface class AdGateway {
  /// Child-directed configuration, then SDK start. Called at most once,
  /// and never for premium users.
  Future<void> initialize();

  /// Loads the next interstitial in the background. Never throws.
  Future<void> preload();

  bool get hasInterstitial;

  /// Shows the loaded interstitial; completes when it is closed or fails.
  Future<void> show();

  /// Drops any loaded ad (e.g. the parent just bought premium).
  void discard();
}

/// Ad unit and app IDs come from the build, never from the repo:
/// `--dart-define=ADMOB_INTERSTITIAL_ID=...` (the app ID goes in
/// `android/local.properties` as `admobAppId=...`). Debug builds fall back
/// to Google's test IDs; release builds without IDs show no ads at all.
abstract final class AdConfig {
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _interstitial = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  static String? get interstitialId => _interstitial.isNotEmpty
      ? _interstitial
      : (kReleaseMode ? null : _testInterstitial);
}

/// Google Mobile Ads (AdMob) in child-directed mode, interstitials only.
class AdMobGateway implements AdGateway {
  AdMobGateway(this._unitId);

  final String _unitId;
  InterstitialAd? _ad;
  bool _loading = false;

  @override
  Future<void> initialize() async {
    // Must be set before the first ad request.
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        ageRestrictedTreatment: AgeRestrictedTreatment.child,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    await MobileAds.instance.initialize();
  }

  @override
  Future<void> preload() async {
    if (_ad != null || _loading) return;
    _loading = true;
    final done = Completer<void>();
    await InterstitialAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          done.complete();
        },
        // No fill or offline: simply no ad this time.
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial not loaded: ${error.message}');
          _loading = false;
          done.complete();
        },
      ),
    );
    return done.future;
  }

  @override
  bool get hasInterstitial => _ad != null;

  @override
  Future<void> show() {
    final ad = _ad;
    _ad = null;
    if (ad == null) return Future.value();
    final closed = Completer<void>();
    void finish(Ad ad) {
      unawaited(ad.dispose());
      if (!closed.isCompleted) closed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, error) => finish(ad),
    );
    unawaited(ad.show());
    return closed.future;
  }

  @override
  void discard() {
    unawaited(_ad?.dispose());
    _ad = null;
  }
}

/// Used when there is no ad unit (release without IDs, or tests).
class NoAdsGateway implements AdGateway {
  const NoAdsGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> preload() async {}

  @override
  bool get hasInterstitial => false;

  @override
  Future<void> show() async {}

  @override
  void discard() {}
}
