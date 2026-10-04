import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_store.dart';

/// Parent setting; toggled in the Parent Area (step 8).
const vibrationEnabledKey = 'settings.vibration_enabled';

/// Light haptic feedback for child taps, respecting the vibration setting.
class Haptics {
  const Haptics(this._enabled);

  final bool Function() _enabled;

  void tap() {
    if (_enabled()) HapticFeedback.lightImpact();
  }
}

final hapticsProvider = Provider<Haptics>((ref) {
  final store = ref.watch(localStoreProvider);
  return Haptics(() => store.getBool(vibrationEnabledKey, fallback: true));
});
