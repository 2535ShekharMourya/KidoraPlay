import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/theme/app_colors.dart';
import 'package:kidoraplay/features/play/colouring.dart';
import 'package:kidoraplay/features/play/colouring_screen.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  test('every page has big areas the size of a fingertip or more', () {
    const size = Size(400, 300);
    for (final page in colouringPages) {
      expect(page.areas.length, greaterThanOrEqualTo(4), reason: page.id);
      for (final (i, area) in page.areas.indexed) {
        final b = area(size).getBounds();
        expect(
          b.shortestSide,
          greaterThanOrEqualTo(20),
          reason: '${page.id} area $i',
        );
      }
    }
  });

  group('colouring', () {
    late FakeAudio audio;
    late ProviderContainer c;

    setUp(() async {
      audio = FakeAudio();
      c = ProviderContainer(
        overrides: testOverrides(audio: audio, catalog: catalog),
      );
      addTearDown(c.dispose);
      await c.read(contentCatalogProvider.future);
      c.listen(colouringControllerProvider, (_, _) {});
    });

    ColouringController ctrl() => c.read(colouringControllerProvider.notifier);
    ColouringState state() => c.read(colouringControllerProvider);

    test('fill every area: a cheer; then the next page', () {
      final areas = colouringPages.first.areas.length;
      for (var i = 0; i < areas; i++) {
        ctrl().fill(i);
      }
      expect(state().complete, isTrue);
      expect(state().done, 1);
      expect(audio.sfx.played.last, Sfx.cheer.asset);
      // Recolouring a finished page doesn't cheer again.
      ctrl().fill(0);
      expect(state().done, 1);

      ctrl().nextPage();
      expect(state().page, 1);
      expect(state().fills, isEmpty);
    });

    test('the colour button says the colour\'s name', () async {
      expect(state().current, AppColors.paintRed);
      await ctrl().nextColour();
      expect(state().current, AppColors.paintYellow);
      expect(audio.voice.played.last, 'assets/audio/en/colour_yellow.m4a');
    });
  });

  testWidgets('a tap fills the top area under the finger', (tester) async {
    await pumpApp(tester, const ColouringScreen(), catalog: catalog);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final paint = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_PagePainter',
    );
    final box = tester.getRect(paint);
    // The house's door (on top of the wall).
    await tester.tapAt(
      box.topLeft + Offset(box.width * 0.45, box.height * 0.8),
    );
    await tester.pump();
    final c = ProviderScope.containerOf(tester.element(paint));
    final fills = c.read(colouringControllerProvider).fills;
    expect(fills.keys, [3]); // the door, not the wall (1)
    await tester.pumpWidget(const SizedBox());
  });
}
