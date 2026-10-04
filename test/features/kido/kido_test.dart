import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/kido_line.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/kido/hint_timer.dart';
import 'package:kidoraplay/features/kido/kido_controller.dart';
import 'package:kidoraplay/features/kido/kido_memory.dart';
import 'package:kidoraplay/features/kido/kido_voice.dart';
import 'package:kidoraplay/features/kido/kido_widget.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  Future<ProviderContainer> containerWith({
    LocalStore? store,
    FakeAudio? audio,
  }) async {
    final c = ProviderContainer(
      overrides: testOverrides(catalog: catalog, store: store, audio: audio),
    );
    addTearDown(c.dispose);
    await c.read(contentCatalogProvider.future);
    return c;
  }

  group('HintTimer', () {
    testWidgets('look at 5 s, point at 10 s, glow at 15 s', (tester) async {
      final levels = <HintLevel>[];
      final timer = HintTimer(onLevel: levels.add)..start();

      await tester.pump(const Duration(milliseconds: 4999));
      expect(levels, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(levels, [HintLevel.look]);
      await tester.pump(const Duration(seconds: 5));
      expect(levels.last, HintLevel.point);
      await tester.pump(const Duration(seconds: 5));
      expect(levels.last, HintLevel.glow);
      timer.stop();
    });

    testWidgets('a tap clears the hint and restarts the clock', (tester) async {
      final levels = <HintLevel>[];
      final timer = HintTimer(onLevel: levels.add)..start();

      await tester.pump(const Duration(seconds: 8));
      expect(timer.level, HintLevel.look);
      timer.reset();
      expect(timer.level, HintLevel.none);
      await tester.pump(const Duration(seconds: 4));
      expect(timer.level, HintLevel.none);
      await tester.pump(const Duration(seconds: 1));
      expect(timer.level, HintLevel.look);
      timer.stop();
    });

    testWidgets('hints never repeat more than twice in a row', (tester) async {
      var points = 0;
      final timer = HintTimer(
        onLevel: (l) => l == HintLevel.point ? points++ : null,
      )..start();

      await tester.pump(const Duration(minutes: 3));
      expect(points, 2);

      timer.reset(); // A tap allows hints again.
      await tester.pump(const Duration(seconds: 10));
      expect(points, 3);
      timer.stop();
    });

    testWidgets('stop silences everything', (tester) async {
      final levels = <HintLevel>[];
      final timer = HintTimer(onLevel: levels.add)..start();
      timer.stop();
      await tester.pump(const Duration(seconds: 30));
      expect(levels, isEmpty);
      expect(timer.isRunning, isFalse);
    });
  });

  group('KidoVoice', () {
    test('bilingual mode: Kido talks in Hindi, filling {item}', () async {
      final c = await containerWith(
        store: LocalStore.inMemory({SettingsKeys.language: 'both'}),
      );
      final cow = catalog.itemById('cow')!;
      expect(c.read(kidoVoiceProvider).clipsFor(KidoEvent.hintTap, item: cow), [
        'assets/audio/hi/kido/yeh_raha.m4a', // "यह रहा!" गाय "को छुओ!"
        'assets/audio/hi/cow.m4a',
        'assets/audio/hi/kido/ko_chhuo.m4a',
      ]);
    });

    test('English mode fills {item} in English', () async {
      final c = await containerWith();
      final cow = catalog.itemById('cow')!;
      expect(c.read(kidoVoiceProvider).clipsFor(KidoEvent.hintTap, item: cow), [
        'assets/audio/en/kido/hint_tap.m4a', // "Here it is! Tap the" cow
        'assets/audio/en/cow.m4a',
      ]);
    });

    test('{item} can be any clip, e.g. a letter', () async {
      final c = await containerWith();
      expect(
        c
            .read(kidoVoiceProvider)
            .clipsFor(
              KidoEvent.hintTap,
              itemAudio: 'assets/audio/letters/a.m4a',
            ),
        ['assets/audio/en/kido/hint_tap.m4a', 'assets/audio/letters/a.m4a'],
      );
    });

    test('fills {n} and {section}', () async {
      final c = await containerWith();
      expect(
        c
            .read(kidoVoiceProvider)
            .clipsFor(
              KidoEvent.sectionDone,
              n: 10,
              section: catalog.section(SectionId.birds),
            ),
        [
          'assets/audio/en/kido/you_learned.m4a',
          'assets/audio/en/ten.m4a',
          'assets/audio/en/sections/birds.m4a',
        ],
      );
    });

    test('praise never repeats the same variant twice in a row', () async {
      final c = ProviderContainer(
        overrides: [
          ...testOverrides(catalog: catalog),
          kidoVoiceProvider.overrideWith(
            (ref) => KidoVoice(ref, random: Random(3)),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(contentCatalogProvider.future);
      final voice = c.read(kidoVoiceProvider);
      String? last;
      for (var i = 0; i < 200; i++) {
        final clip = voice.clipsFor(KidoEvent.praise).single;
        expect(clip, isNot(last));
        last = clip;
      }
    });

    test('say plays through the audio service', () async {
      final audio = FakeAudio();
      final c = await containerWith(audio: audio);
      final ok = await c.read(kidoVoiceProvider).say(KidoEvent.welcomeBack);
      expect(ok, isTrue);
      expect(audio.voice.played, ['assets/audio/en/kido/welcome_back.m4a']);
    });
  });

  group('KidoController', () {
    testWidgets('one-shot actions return to idle; held actions stay', (
      tester,
    ) async {
      final c = await tester.runAsync(containerWith);
      final kido = c!.read(kidoControllerProvider.notifier)
        ..act(KidoAction.wave);
      expect(c.read(kidoControllerProvider).action, KidoAction.wave);
      await tester.pump(KidoAction.wave.oneShot!);
      expect(c.read(kidoControllerProvider).action, KidoAction.idle);

      kido.act(KidoAction.point, target: const Offset(10, 20));
      await tester.pump(const Duration(seconds: 5));
      expect(c.read(kidoControllerProvider).action, KidoAction.point);
      expect(c.read(kidoControllerProvider).target, const Offset(10, 20));
    });

    test('repeating an action bumps seq so it replays', () async {
      final c = await containerWith();
      final kido = c.read(kidoControllerProvider.notifier)
        ..act(KidoAction.point);
      final seq = c.read(kidoControllerProvider).seq;
      kido.act(KidoAction.point);
      expect(c.read(kidoControllerProvider).seq, seq + 1);
    });
  });

  group('KidoMemory', () {
    test('first visit gets full guidance, later visits do not', () async {
      final store = LocalStore.inMemory();
      final c = await containerWith(store: store);
      final memory = c.read(kidoMemoryProvider);
      expect(memory.fullGuidance(SectionId.abc), isTrue);

      await memory.enterSection(SectionId.abc);
      expect(memory.fullGuidance(SectionId.abc), isTrue); // this visit
      await memory.enterSection(SectionId.abc);
      expect(memory.fullGuidance(SectionId.abc), isFalse); // next visit

      // Remembered across app restarts.
      final c2 = await containerWith(store: store);
      expect(c2.read(kidoMemoryProvider).visited(SectionId.abc), isTrue);
    });

    test('greets once per session', () async {
      final c = await containerWith();
      final memory = c.read(kidoMemoryProvider);
      expect(memory.takeSessionGreeting(), isTrue);
      expect(memory.takeSessionGreeting(), isFalse);
    });
  });

  group('KidoWidget', () {
    for (final reduceMotion in [false, true]) {
      testWidgets(
        'draws every action${reduceMotion ? ' (reduced motion)' : ''}',
        (tester) async {
          final audio = FakeAudio();
          late WidgetRef ref;
          await pumpApp(
            tester,
            Stack(
              children: [
                Consumer(
                  builder: (context, r, _) {
                    ref = r;
                    return const SizedBox.expand();
                  },
                ),
                const KidoCorner(),
              ],
            ),
            audio: audio,
            reduceMotion: reduceMotion,
          );
          for (final action in KidoAction.values) {
            ref
                .read(kidoControllerProvider.notifier)
                .act(action, target: const Offset(400, 100));
            await tester.pump(const Duration(milliseconds: 200));
            expect(tester.takeException(), isNull, reason: action.name);
          }
          audio.voice.holdPlayback = true;
          final talking = ref
              .read(audioServiceProvider)
              .playVoice('assets/x.m4a');
          await tester.pump(AppDurations.kidoTalk);
          expect(ref.read(audioServiceProvider).speaking.value, isTrue);
          expect(tester.takeException(), isNull);
          audio.voice.finishCurrent();
          await tester.runAsync(() => talking);
          await tester.pump(const Duration(seconds: 2));
        },
      );
    }

    testWidgets('sits bottom-left inside the free left column', (tester) async {
      await pumpApp(tester, const Stack(children: [KidoCorner()]));
      final rect = tester.getRect(find.byType(KidoWidget));
      expect(rect.right, lessThanOrEqualTo(AppLayout.sideZone));
      expect(rect.bottom, greaterThan(300));
      // About a fifth of the screen height (360).
      expect(rect.height, inInclusiveRange(360 * 0.18, 360 * 0.22));
    });
  });
}
