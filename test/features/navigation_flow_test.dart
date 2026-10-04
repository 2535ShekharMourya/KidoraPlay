import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kidoraplay/app.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/arrow_button.dart';
import 'package:kidoraplay/core/widgets/big_back_button.dart';
import 'package:kidoraplay/core/widgets/item_picture.dart';
import 'package:kidoraplay/core/widgets/letter_tile.dart';
import 'package:kidoraplay/features/home/home_screen.dart';
import 'package:kidoraplay/features/learn_card/learn_card_screen.dart';
import 'package:kidoraplay/features/numbers/number_rows_screen.dart';
import 'package:kidoraplay/features/section_grid/item_grid_screen.dart';

import '../helpers/fake_audio.dart';
import '../helpers/pump_app.dart';

/// Screens loop idle animations, so advance time instead of settling.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  Future<FakeAudio> startApp(WidgetTester tester) async {
    final audio = FakeAudio();
    useLandscapePhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(audio: audio, catalog: catalog),
        child: const KidoraApp(),
      ),
    );
    await tester.pump(AppDurations.splash);
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    return audio;
  }

  testWidgets('Numbers: home → rows → 21–30 → Twenty-one → back', (
    tester,
  ) async {
    final audio = await startApp(tester);

    await tester.tap(find.text('Numbers'));
    await settle(tester);
    expect(find.byType(NumberRowsScreen), findsOneWidget);
    expect(audio.voice.played.last, 'assets/audio/en/sections/numbers.m4a');

    await tester.tap(find.bySemanticsLabel('21 to 30'));
    await settle(tester);
    expect(find.byType(ItemGridScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Twenty-one'));
    await settle(tester);
    expect(find.byType(LearnCardScreen), findsOneWidget);
    expect(find.text('Twenty-one'), findsOneWidget);
    expect(find.byType(LetterTile), findsNWidgets('TWENTY-ONE'.length));
    // The lesson started on its own.
    expect(audio.voice.played, contains('assets/audio/en/twenty_one.m4a'));

    await tester.tap(find.byType(BigBackButton));
    await settle(tester);
    expect(find.byType(ItemGridScreen), findsOneWidget);
    expect(find.byType(LearnCardScreen), findsNothing);
  });

  testWidgets('ABC: next arrow moves to the next item', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('ABC'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Apple'));
    await settle(tester);
    expect(find.text('Apple'), findsOneWidget);
    // First item: no previous arrow.
    expect(find.byType(ArrowButton), findsOneWidget);

    await tester.tap(find.byType(ArrowButton));
    await settle(tester);
    expect(find.text('Ball'), findsOneWidget);
    expect(find.byType(ArrowButton), findsNWidgets(2));
  });

  testWidgets('tapping the picture replays the lesson', (tester) async {
    final audio = await startApp(tester);
    await tester.tap(find.text('Animals'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Lion'));
    await settle(tester);
    final firstRun = audio.voice.played.length;

    await tester.tap(
      find.descendant(
        of: find.byType(LearnCardScreen),
        matching: find.byType(ItemPicture),
      ),
    );
    await settle(tester);
    expect(audio.voice.played.length, greaterThan(firstRun));
    expect(
      audio.voice.played.sublist(firstRun),
      contains('assets/audio/en/kido/look.m4a'),
    );
    // Close the app so lesson and hint timers end with it.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('unknown section link goes home', (tester) async {
    await startApp(tester);
    final context = tester.element(find.byType(HomeScreen));
    GoRouterHelper(context).go('/home/section/dinosaurs');
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
