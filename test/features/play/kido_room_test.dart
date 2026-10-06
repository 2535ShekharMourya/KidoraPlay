import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/games/quiz_controller.dart';
import 'package:kidoraplay/features/play/kido_room_controller.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  test('where a tap lands on Kido', () {
    expect(KidoSpot.at(const Offset(0.6, 0.35)), KidoSpot.head);
    expect(KidoSpot.at(const Offset(0.45, 0.15)), KidoSpot.head); // ear top
    expect(KidoSpot.at(const Offset(0.9, 0.6)), KidoSpot.trunk);
    expect(KidoSpot.at(const Offset(0.4, 0.75)), KidoSpot.body);
  });

  group('playing with Kido', () {
    late FakeAudio audio;
    late ProviderContainer c;

    setUp(() async {
      audio = FakeAudio();
      c = ProviderContainer(
        overrides: [
          ...testOverrides(
            audio: audio,
            catalog: catalog,
            store: LocalStore.inMemory({SettingsKeys.language: 'en'}),
          ),
          quizRandomProvider.overrideWithValue(math.Random(1)),
        ],
      );
      addTearDown(c.dispose);
      await c.read(contentCatalogProvider.future);
      c.listen(kidoRoomControllerProvider, (_, _) {});
    });

    KidoRoomController room() => c.read(kidoRoomControllerProvider.notifier);
    KidoRoomState state() => c.read(kidoRoomControllerProvider);

    test('a pat, a tickle, and a real trumpet', () async {
      await room().touch(KidoSpot.head);
      expect(
        audio.voice.played.last,
        startsWith('assets/audio/en/kido/room_pat_'),
      );
      await room().touch(KidoSpot.body);
      expect(
        audio.voice.played.last,
        startsWith('assets/audio/en/kido/room_tickle_'),
      );
      await room().touch(KidoSpot.trunk);
      expect(audio.voice.played.last, 'assets/audio/animals/elephant.m4a');
    });

    test('feeding: a fruit, and "Yum yum!" with its name', () async {
      await room().feed();
      final fruit = state().food!;
      expect(fruit.section.name, 'fruits');
      expect(audio.voice.played.sublist(audio.voice.played.length - 2), [
        'assets/audio/en/kido/yum.m4a',
        fruit.voiceEn,
      ]);
      await room().feed();
      expect(state().feeds, 2);
      expect(state().food!.id, isNot(fruit.id)); // not the same twice
    });

    test('bath time and hats (crown, cap, top hat, none)', () async {
      await room().bath();
      expect(state().baths, 1);
      expect(
        audio.voice.played.last,
        startsWith('assets/audio/en/kido/room_bath_'),
      );
      final hats = <KidoHat?>[];
      for (var i = 0; i < 4; i++) {
        await room().nextHat();
        hats.add(state().hat);
      }
      expect(hats, [KidoHat.crown, KidoHat.cap, KidoHat.topHat, null]);
    });
  });
}
