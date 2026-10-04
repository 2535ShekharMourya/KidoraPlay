import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';

import '../../helpers/fake_audio.dart';

void main() {
  late FakeAudio audio;
  late DateTime now;
  late AudioService service;

  AudioService create({AppSettings settings = const AppSettings()}) =>
      AudioService(
        voice: audio.voice,
        sfx: audio.sfx,
        music: audio.music,
        settings: settings,
        clock: () => now,
      );

  setUp(() {
    audio = FakeAudio();
    now = DateTime(2026);
    service = create();
  });

  group('voice', () {
    test('plays a clip and reports completion', () async {
      expect(await service.playVoice('a.m4a'), isTrue);
      expect(audio.voice.played, ['a.m4a']);
      expect(service.isSpeaking, isFalse);
    });

    test('a new line stops the old one; nothing is queued', () async {
      audio.voice.holdPlayback = true;
      final first = service.playVoiceSequence(['one.m4a', 'two.m4a']);
      await pumpEventQueue();
      expect(service.isSpeaking, isTrue);

      now = now.add(const Duration(seconds: 1));
      final second = service.playVoice('new.m4a');
      await pumpEventQueue();
      expect(await first, isFalse);
      audio.voice.finishCurrent();
      expect(await second, isTrue);

      // "two.m4a" never played: the interrupted sequence did not continue.
      expect(audio.voice.played, ['one.m4a', 'new.m4a']);
      expect(audio.voice.stops, 1);
    });

    test('sequence reports each segment before it plays', () async {
      final segments = <int>[];
      final ok = await service.playVoiceSequence(
        ['A', 'P', 'P', 'L', 'E'],
        onSegment: segments.add,
      );
      expect(ok, isTrue);
      expect(segments, [0, 1, 2, 3, 4]);
      expect(audio.voice.played, ['A', 'P', 'P', 'L', 'E']);
    });

    test('identical request within 250 ms is ignored', () async {
      await service.playVoice('cow.m4a');
      now = now.add(const Duration(milliseconds: 100));
      expect(await service.playVoice('cow.m4a'), isFalse);
      now = now.add(const Duration(milliseconds: 200));
      expect(await service.playVoice('cow.m4a'), isTrue);
      expect(audio.voice.played, ['cow.m4a', 'cow.m4a']);
    });

    test('a different clip is not debounced', () async {
      await service.playVoice('cow.m4a');
      expect(await service.playVoice('hen.m4a'), isTrue);
    });

    test('missing audio fails quietly and audio keeps working', () async {
      audio.voice.failing.add('missing.m4a');
      expect(await service.playVoice('missing.m4a'), isFalse);
      expect(service.isSpeaking, isFalse);
      expect(await service.playVoice('ok.m4a'), isTrue);
    });

    test('stopVoice interrupts', () async {
      audio.voice.holdPlayback = true;
      final playing = service.playVoice('long.m4a');
      await pumpEventQueue();
      await service.stopVoice();
      expect(await playing, isFalse);
      expect(service.isSpeaking, isFalse);
    });
  });

  group('sfx', () {
    test('plays and preloads every effect', () async {
      service.playSfx(Sfx.pop);
      await service.preloadSfx();
      await pumpEventQueue();
      expect(audio.sfxNames, ['pop']);
      expect(audio.sfx.preloaded, [for (final s in Sfx.values) s.asset]);
    });

    test('failures are swallowed', () async {
      audio.sfx.fail = true;
      service.playSfx(Sfx.cheer);
      await service.preloadSfx();
      await pumpEventQueue();
      expect(audio.sfx.played, isEmpty);
    });
  });

  group('music', () {
    const withMusic = AppSettings(musicEnabled: true);

    test('is off by default', () async {
      await service.applySettings(const AppSettings());
      expect(audio.music.playing, isFalse);
    });

    test('starts when enabled and stops when disabled', () async {
      await service.applySettings(withMusic);
      expect(audio.music.track, AudioAssets.homeMusic);
      expect(audio.music.volume, AudioLevels.music);

      await service.applySettings(const AppSettings());
      expect(audio.music.playing, isFalse);
    });

    test('ducks to 30% while Kido speaks, then restores', () async {
      await service.applySettings(withMusic);
      audio.voice.holdPlayback = true;
      final speaking = service.playVoice('hi.m4a');
      await pumpEventQueue();
      expect(
        audio.music.volume,
        closeTo(AudioLevels.music * AudioLevels.duckFactor, 1e-9),
      );

      audio.voice.finishCurrent();
      await speaking;
      expect(audio.music.volume, AudioLevels.music);
    });
  });

  group('settings and lifecycle', () {
    test('sound off silences voice, sfx and music', () async {
      await service.applySettings(
        const AppSettings(soundEnabled: false, musicEnabled: true),
      );
      service.playSfx(Sfx.pop);
      expect(await service.playVoice('a.m4a'), isFalse);
      await pumpEventQueue();
      expect(audio.voice.played, isEmpty);
      expect(audio.sfx.played, isEmpty);
      expect(audio.music.playing, isFalse);
    });

    test('muting stops a line that is already playing', () async {
      audio.voice.holdPlayback = true;
      final playing = service.playVoice('a.m4a');
      await pumpEventQueue();
      await service.applySettings(const AppSettings(soundEnabled: false));
      expect(await playing, isFalse);
    });

    test('background pauses everything; foreground resumes music', () async {
      await service.applySettings(const AppSettings(musicEnabled: true));
      audio.voice.holdPlayback = true;
      final playing = service.playVoice('a.m4a');
      await pumpEventQueue();

      await service.pauseAll();
      expect(await playing, isFalse);
      expect(audio.music.playing, isFalse);
      expect(await service.playVoice('b.m4a'), isFalse);

      await service.resumeAll();
      expect(audio.music.playing, isTrue);
    });
  });
}
