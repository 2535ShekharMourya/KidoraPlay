import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/item_picture.dart';
import 'package:kidoraplay/features/play/tap_play_screen.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  testWidgets('a tap anywhere pops up a friend with its sound and name', (
    tester,
  ) async {
    final audio = FakeAudio();
    await pumpApp(
      tester,
      TapPlayScreen(random: math.Random(2)),
      audio: audio,
      catalog: catalog,
    );
    await tester.pump(const Duration(milliseconds: 100));
    audio.voice.played.clear();

    await tester.tapAt(const Offset(400, 200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ItemPicture), findsOneWidget);
    expect(audio.sfxNames, contains('pop'));
    // Its real sound (if it has one), then its name.
    expect(audio.voice.played.last, startsWith('assets/audio/en/'));

    // Taps keep coming; at most five friends at once.
    for (var i = 0; i < 7; i++) {
      await tester.tapAt(Offset(150.0 + i * 70, 180));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      find.byType(ItemPicture).evaluate().length,
      lessThanOrEqualTo(TapPlayScreenLimits.maxPops),
    );

    // They float away by themselves.
    await tester.pump(AppDurations.tapPlayLife);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ItemPicture), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
