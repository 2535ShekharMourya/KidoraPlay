import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio/just_audio.dart' as ja;

import 'audio_players.dart';

/// Voice channel on just_audio. A new [play] replaces the current clip.
class JustAudioVoicePlayer implements VoicePlayer {
  final _player = ja.AudioPlayer(handleInterruptions: false);

  @override
  Future<void> play(String asset) async {
    await _player.setAsset(asset);
    // play() only completes on pause/stop, so wait for completion or stop.
    final done = _player.processingStateStream.firstWhere(
      (s) => s == ja.ProcessingState.completed || s == ja.ProcessingState.idle,
    );
    unawaited(_player.play());
    await done;
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// Music channel on just_audio, looping one track.
class JustAudioMusicPlayer implements MusicPlayer {
  final _player = ja.AudioPlayer(handleInterruptions: false);

  @override
  Future<void> start(String asset, {required double volume}) async {
    await _player.setAsset(asset);
    await _player.setLoopMode(ja.LoopMode.one);
    await _player.setVolume(volume);
    unawaited(_player.play());
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async => unawaited(_player.play());

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// SFX channel on audioplayers' low-latency pools (SoundPool on Android).
/// Mixes with other audio so a tap sound never pauses Kido's voice.
class AudioplayersSfxPlayer implements SfxPlayer {
  AudioplayersSfxPlayer()
      : _cache = ap.AudioCache(prefix: ''),
        _context = ap.AudioContextConfig(
          focus: ap.AudioContextConfigFocus.mixWithOthers,
        ).build();

  final ap.AudioCache _cache;
  final ap.AudioContext _context;
  final _pools = <String, Future<ap.AudioPool>>{};

  Future<ap.AudioPool> _pool(String asset) => _pools[asset] ??=
      ap.AudioPool.create(
        source: ap.AssetSource(asset),
        audioCache: _cache,
        audioContext: _context,
        maxPlayers: 3,
        playerMode: ap.PlayerMode.lowLatency,
      );

  @override
  Future<void> preload(Iterable<String> assets) =>
      Future.wait([for (final a in assets) _pool(a)]);

  @override
  Future<void> play(String asset) async {
    await (await _pool(asset)).start();
  }

  @override
  Future<void> dispose() async {
    for (final pool in _pools.values) {
      await (await pool).dispose();
    }
    _pools.clear();
  }
}
