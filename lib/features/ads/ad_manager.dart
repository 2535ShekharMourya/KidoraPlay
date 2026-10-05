import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_service.dart';
import '../billing/billing_controller.dart';
import 'ad_break_screen.dart';
import 'ad_gateway.dart';
import 'ad_rules.dart';

/// Decides if and when a child-safe interstitial appears.
///
/// Screens call [maybeShowBreak] only at natural breaks (a finished section
/// or game). It never blocks or delays the child: no ad loaded, offline, or
/// too soon simply means no ad. Premium users never start the ad SDK.
class AdManager {
  AdManager(this._ref, this._gateway, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _sessionStart = _now();
  }

  final Ref _ref;
  final AdGateway _gateway;
  final DateTime Function() _now;
  late final DateTime _sessionStart;
  DateTime? _lastShown;
  bool _started = false;
  bool _busy = false;

  bool get _premium => _ref.read(isPremiumProvider);

  /// Starts the SDK in the background (after the premium check) and loads
  /// the first ad. Safe to call more than once.
  Future<void> start() async {
    if (_started || _premium) return;
    _started = true;
    try {
      await _gateway.initialize();
      await _gateway.preload();
    } on Object catch (e) {
      debugPrint('Ads unavailable: $e');
    }
  }

  /// At a natural break ([reason], e.g. "section_done"): maybe shows Kido's
  /// break screen and then an interstitial. Returns whether it did.
  Future<bool> maybeShowBreak(
    BuildContext context, {
    required String reason,
  }) async {
    if (!_started || _busy) return false;
    if (_premium) {
      _gateway.discard();
      return false;
    }
    final allowed = AdRules.canShow(
      premium: false,
      sessionStart: _sessionStart,
      lastShown: _lastShown,
      now: _now(),
    );
    if (!allowed) return false;
    if (!_gateway.hasInterstitial) {
      unawaited(_gateway.preload());
      return false;
    }
    if (!context.mounted) return false;

    _busy = true;
    _lastShown = _now();
    final audio = _ref.read(audioServiceProvider);
    try {
      await audio.stopVoice();
      if (!context.mounted) return false;
      await showAdBreak(context);
      if (_premium) return false;
      await audio.pauseAll();
      await _gateway.show();
      return true;
    } on Object catch (e) {
      debugPrint('Ad break ($reason) skipped: $e');
      return false;
    } finally {
      await audio.resumeAll();
      _busy = false;
      unawaited(_gateway.preload());
    }
  }
}

final adGatewayProvider = Provider<AdGateway>((ref) {
  final id = AdConfig.interstitialId;
  return id == null ? const NoAdsGateway() : AdMobGateway(id);
});

/// The clock the ad rules use; replaced in tests.
final adClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Premium is checked on every offer (a parent may buy it mid-session),
/// so a loaded ad is dropped the moment it would otherwise be shown.
final adManagerProvider = Provider<AdManager>(
  (ref) => AdManager(
    ref,
    ref.watch(adGatewayProvider),
    now: ref.watch(adClockProvider),
  ),
);
