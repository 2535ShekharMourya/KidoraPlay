import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/app.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/bouncy_button.dart';
import 'package:kidoraplay/features/home/home_screen.dart';
import 'package:kidoraplay/features/splash/splash_screen.dart';

import 'helpers/fake_audio.dart';
import 'helpers/pump_app.dart';

const sections = ['Numbers', 'ABC', 'Animals', 'Birds'];

Future<void> pumpToHome(
  WidgetTester tester, {
  FakeAudio? audio,
  ContentCatalog? catalog,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(audio: audio),
        if (catalog != null)
          contentCatalogProvider.overrideWith((ref) async => catalog),
      ],
      child: const KidoraApp(),
    ),
  );
  expect(find.byType(SplashScreen), findsOneWidget);
  // Home has looping idle animations, so pump fixed time instead of settling.
  await tester.pump(AppDurations.splash);
  await tester.pump(AppDurations.pageTransition);
  await tester.pump(AppDurations.popIn + AppDurations.staggerStep * 4);
}

void main() {
  late ContentCatalog catalog;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Load the real bundled content once, outside the widget tests' fake
    // clock.
    catalog =
        await ContentRepository(bundle: rootBundle, validate: false).load();
  });

  testWidgets('starts on splash, then shows home with 4 sections',
      (tester) async {
    await pumpToHome(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    for (final label in sections) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('section tiles meet the 96 dp minimum tap target',
      (tester) async {
    await pumpToHome(tester);
    for (final label in sections) {
      final tile = find.ancestor(
        of: find.text(label),
        matching: find.byType(BouncyButton),
      );
      final size = tester.getSize(tile);
      expect(size.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    }
  });

  testWidgets('tapping a section tile gives haptic feedback', (tester) async {
    final haptics = recordHaptics(tester);
    await pumpToHome(tester);
    await tester.tap(find.text('Animals'));
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await tester.pump(AppDurations.tapBounce);
  });

  testWidgets('tapping a section tile pops and says the section name',
      (tester) async {
    final audio = FakeAudio();
    await pumpToHome(tester, audio: audio, catalog: catalog);
    await tester.tap(find.text('Birds'));
    await tester.pump();
    expect(audio.sfxNames, ['pop']);
    expect(audio.voice.played, ['assets/audio/en/sections/birds.m4a']);
    await tester.pump(AppDurations.tapBounce);
  });
}
