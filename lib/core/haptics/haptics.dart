import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';

/// Light haptic feedback for child taps, respecting the vibration setting.
class Haptics {
  const Haptics(this._enabled);

  final bool Function() _enabled;

  void tap() {
    if (_enabled()) HapticFeedback.lightImpact();
  }
}

final hapticsProvider = Provider<Haptics>(
  (ref) => Haptics(() => ref.read(settingsProvider).vibrationEnabled),
);
