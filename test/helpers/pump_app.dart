import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_theme.dart';
import 'package:kidoraplay/l10n/app_localizations.dart';

import 'fake_audio.dart';

/// Landscape phone: 2400×1080 physical at 3x (800×360 logical).
void useLandscapePhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(2400, 1080)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Provider overrides every widget test needs: in-memory storage and fake
/// audio channels.
List<Override> testOverrides({LocalStore? store, FakeAudio? audio}) => [
      localStoreProvider.overrideWithValue(store ?? LocalStore.inMemory()),
      audioChannelsProvider.overrideWithValue((audio ?? FakeAudio()).channels),
    ];

/// Pumps [child] inside the app's theme, localizations and a ProviderScope
/// with an in-memory [LocalStore] and fake audio.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  LocalStore? store,
  FakeAudio? audio,
  bool reduceMotion = false,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(store: store, audio: audio),
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Records haptic feedback calls sent to the platform.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}
