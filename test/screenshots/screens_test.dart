// Renders every main screen to PNG for visual inspection (layout, overlap,
// cut-off text) without a device. Off by default; run with:
//
//   flutter test test/screenshots --dart-define=SCREENSHOTS=true
//
// Images land in build/screenshots/<size>/<name>.png.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kidoraplay/app.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/core/router/app_router.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/games/quiz_models.dart';
import 'package:kidoraplay/features/home/home_screen.dart';
import 'package:kidoraplay/features/learn_card/learn_card_controller.dart';
import 'package:kidoraplay/features/tracing/trace_logic.dart';

import '../helpers/fake_audio.dart';
import '../helpers/pump_app.dart';

const enabled = bool.fromEnvironment('SCREENSHOTS');

const sizes = {
  'phone_800x360': Size(2400, 1080), // 20:9 at 3x (most budget phones)
  'phone_640x360': Size(1280, 720), // 16:9 at 2x (older phones)
  'tablet_1280x800': Size(2560, 1600), // 16:10 at 2x
};

Future<void> loadFonts() async {
  final baloo = FontLoader('Baloo2')
    ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
  await baloo.load();
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter'}'
    '/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  final material = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await material.load();
}

void main() {
  late ContentCatalog catalog;
  late TraceGuides guides;
  setUpAll(() async {
    catalog = await loadTestCatalog();
    guides = await loadTraceGuides(rootBundle);
    await loadFonts();
  });

  final boundary = GlobalKey();

  Future<void> settle(WidgetTester tester, {int frames = 15}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Let real image decoding finish, then paint it.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> shoot(WidgetTester tester, String size, String name) async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/screenshots/$size/$name.png')
        ..createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  for (final MapEntry(key: size, value: physical) in sizes.entries) {
    for (final level in ['nursery', 'ukg']) {
      testWidgets('screens $size $level', (tester) async {
        tester.view
          ..physicalSize = physical
          ..devicePixelRatio = physical.width > 2000 && physical.height > 1500
              ? 2
              : physical.width / (physical.width >= 2400 ? 800 : 640);
        addTearDown(tester.view.reset);
        final audio = FakeAudio();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...testOverrides(
                audio: audio,
                catalog: catalog,
                store: LocalStore.inMemory({
                  SettingsKeys.language: 'both',
                  SettingsKeys.level: level,
                  'progress.learned': ['cow', 'lion', 'one', 'two'],
                }),
              ),
              traceGuidesProvider.overrideWith((ref) async => guides),
            ],
            child: RepaintBoundary(key: boundary, child: const KidoraApp()),
          ),
        );
        await tester.pump(AppDurations.splash);
        await settle(tester);
        final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

        Future<void> go(String path, String name, {int frames = 25}) async {
          router.go(path);
          await settle(tester, frames: frames);
          await shoot(tester, size, '${level}_$name');
        }

        await shoot(tester, size, '${level}_home');
        if (level == 'ukg') {
          await tester.tap(find.bySemanticsLabel('Next').first);
          await settle(tester);
          await shoot(tester, size, '${level}_home_page2');
        }
        await go(AppRoutes.section(SectionId.animals), 'grid_animals');
        await go(AppRoutes.section(SectionId.numbers), 'numbers_rows');
        await go(AppRoutes.numberRow(3), 'numbers_row3');
        for (final (section, id) in [
          (SectionId.animals, 'cow'),
          (SectionId.abc, 'a_apple'),
          (SectionId.hindi, 'hi_anar'),
          (SectionId.colours, 'colour_red'),
          (SectionId.body, 'body_nose'),
          if (level == 'ukg') ...[
            (SectionId.family, 'family_grandmother'),
            (SectionId.days, 'day_wednesday'),
            (SectionId.months, 'month_september'),
            (SectionId.opposites, 'opp_big'),
          ],
        ]) {
          await go(
            AppRoutes.learn((section: section, row: null), id),
            'learn_$id',
            frames: 40,
          );
        }
        // A card mid-discovery, with a star earned.
        final ctrl = ProviderScope.containerOf(
          tester.element(find.byType(KidoraApp)),
        ).read(learnCardControllerProvider('opp_big').notifier);
        if (level == 'ukg') {
          await ctrl.tapPicture();
          await settle(tester, frames: 30);
          await shoot(tester, size, '${level}_learn_opp_big_star');
        }
        await go(
          AppRoutes.learn((section: SectionId.numbers, row: 3), 'twenty_one'),
          'learn_twenty_one',
          frames: 40,
        );
        await go(
          AppRoutes.trace((section: SectionId.abc, row: null), 'a_apple'),
          'trace_a',
          frames: 30,
        );
        await go(
          AppRoutes.trace((section: SectionId.numbers, row: 3), 'twenty_one'),
          'trace_21',
          frames: 30,
        );
        await go(AppRoutes.games, 'games');
        for (final kind in GameKind.values) {
          await go(AppRoutes.game(kind), 'game_${kind.name}', frames: 30);
        }
        await go(AppRoutes.stickers, 'stickers');
        await go(AppRoutes.parent, 'parent_gate');

        // End cleanly: no timers left behind.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      }, skip: !enabled);
    }
  }
}
