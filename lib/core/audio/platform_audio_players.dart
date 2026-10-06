import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio/just_audio.dart' as ja;

import 'audio_players.dart';

/// Voice channel on just_audio. A new [play] replaces the current clip.
///
/// Built for a toddler tapping fast on a slow phone: a request that a newer
/// one interrupts just ends quietly (it is not an error), a clip that
/// takes too long to load gives up instead of hanging, and a sentence
/// that can't load as one smooth playlist is played clip by clip.
class JustAudioVoicePlayer implements VoicePlayer {
  final _player = ja.AudioPlayer(handleInterruptions: false);

  /// Grace time on top of a clip's length before we give up on it, so a
  /// clip that never reports completion can't stall a lesson.
  static const _grace = Duration(seconds: 2);
  static const _unknownLength = Duration(seconds: 8);

  /// Longest we wait for a clip to load before giving up on it.
  static const _loadTimeout = Duration(seconds: 3);

  /// Each new playback (or stop) bumps this, so a superseded one ends.
  int _generation = 0;

  @override
  Future<void> play(String asset) async {
    final generation = ++_generation;
    final Duration? length;
    try {
      length = await _player.setAsset(asset).timeout(_loadTimeout);
    } on ja.PlayerInterruptedException {
      return; // A newer request took over.
    }
    if (generation != _generation) return;
    await _playLoaded(length ?? _unknownLength, asset);
  }

  @override
  Future<void> playAll(
    List<String> assets, {
    void Function(int index)? onIndex,
  }) async {
    if (assets.isEmpty) return;
    if (assets.length == 1) {
      onIndex?.call(0);
      return play(assets.single);
    }
    final generation = ++_generation;
    // One gapless playlist: the next clip is already loaded when the
    // current one ends, so stitched lines sound like one sentence.
    try {
      await _player
          .setAudioSources([for (final a in assets) ja.AudioSource.asset(a)])
          .timeout(_loadTimeout);
    } on ja.PlayerInterruptedException {
      return; // A newer request took over.
    } on Object {
      if (generation != _generation) return;
      // The playlist wouldn't load: play the clips one by one instead.
      // Each play() takes the next generation; anything else (a stop or a
      // newer request) means this sequence was interrupted.
      var expected = generation;
      for (var i = 0; i < assets.length; i++) {
        if (_generation != expected) return;
        onIndex?.call(i);
        await play(assets[i]);
        expected++;
      }
      return;
    }
    if (generation != _generation) return;
    var last = -1;
    final sub = _player.currentIndexStream.listen((i) {
      if (i != null && i > last && generation == _generation) {
        last = i;
        onIndex?.call(i);
      }
    });
    try {
      await _playLoaded(_unknownLength * assets.length, assets.join(', '));
    } finally {
      await sub.cancel();
    }
  }

  /// Plays what is loaded and waits until it ends or is stopped.
  Future<void> _playLoaded(Duration length, String what) async {
    // play() only completes on pause/stop, so wait for completion or stop.
    final done = _player.processingStateStream.firstWhere(
      (s) => s == ja.ProcessingState.completed || s == ja.ProcessingState.idle,
    );
    unawaited(_player.play());
    await done.timeout(
      length + _grace,
      onTimeout: () async {
        await _player.stop();
        throw TimeoutException('voice did not finish: $what');
      },
    );
  }

  @override
  Future<void> stop() {
    _generation++;
    return _player.stop();
  }

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

  Future<ap.AudioPool> _pool(String asset) =>
      _pools[asset] ??= ap.AudioPool.create(
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
