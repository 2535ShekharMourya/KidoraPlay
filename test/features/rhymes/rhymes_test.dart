import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/rhymes/rhyme.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late List<Rhyme> rhymes;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    rhymes = await loadRhymes(rootBundle);
  });

  test('seven safe rhymes; every tune note, voice and picture exists', () {
    expect(rhymes, hasLength(7));
    expect(rhymes.where((r) => r.language == ContentLanguage.hi), hasLength(3));
    for (final r in rhymes) {
      expect(r.lines, isNotEmpty, reason: r.id);
      for (final l in r.lines) {
        expect(l.tune, isNotEmpty, reason: '${r.id}: ${l.text}');
      }
      for (final a in r.assets) {
        expect(File(a).existsSync(), isTrue, reason: '${r.id}: $a');
      }
    }
    // Babies get rhymes too.
    expect(
      rhymes.where((r) => r.levels.contains(Level.baby)).length,
      greaterThanOrEqualTo(5),
    );
  });

  testWidgets('each line: its tune, then Kido says it; then a cheer', (
    tester,
  ) async {
    final audio = FakeAudio();
    final c = ProviderContainer(overrides: testOverrides(audio: audio));
    addTearDown(c.dispose);
    final rain = rhymes.firstWhere((r) => r.id == 'rain_rain');
    final lines = <int?>[];
    c.listen(rhymeControllerProvider('rain_rain'), (_, s) => lines.add(s.line));

    final playing = c
        .read(rhymeControllerProvider('rain_rain').notifier)
        .play(rain);
    // Long enough for every beat of every line.
    for (var i = 0; i < 200; i++) {
      await tester.pump(AppDurations.rhymeBeat);
    }
    await playing;

    expect(audio.voice.played, [for (final l in rain.lines) l.voice]);
    final notes = audio.sfx.played.where((a) => a.contains('/notes/')).toList();
    expect(notes, [
      for (final l in rain.lines)
        for (final n in l.tune) noteAsset(n.pitch),
    ]);
    // The lines lit up in order.
    expect(lines.whereType<int>().toSet().toList(), [
      for (var i = 0; i < rain.lines.length; i++) i,
    ]);
    final s = c.read(rhymeControllerProvider('rain_rain'));
    expect(s.finished, 1);
    expect(s.playing, isFalse);
    expect(audio.sfx.played.last, Sfx.cheer.asset);
  });
}
