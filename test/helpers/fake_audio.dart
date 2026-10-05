import 'dart:async';

import 'package:kidoraplay/core/audio/audio_players.dart';
import 'package:kidoraplay/core/audio/audio_service.dart';

/// Records what was played. By default clips "finish" immediately; set
/// [holdPlayback] to keep each clip playing until [finishCurrent] or stop.
class FakeVoicePlayer implements VoicePlayer {
  final played = <String>[];
  final failing = <String>{};
  int stops = 0;
  bool holdPlayback = false;
  Completer<void>? _current;

  bool get isPlaying => _current != null && !_current!.isCompleted;
  int _generation = 0;

  @override
  Future<void> play(String asset) async {
    played.add(asset);
    if (failing.contains(asset)) throw Exception('cannot play $asset');
    if (holdPlayback) {
      _current = Completer<void>();
      await _current!.future;
    }
  }

  void finishCurrent() {
    if (isPlaying) _current!.complete();
  }

  /// Like the real player: clip by clip, stopping early if stopped.
  @override
  Future<void> playAll(
    List<String> assets, {
    void Function(int index)? onIndex,
  }) async {
    final generation = ++_generation;
    for (var i = 0; i < assets.length; i++) {
      if (generation != _generation) return;
      onIndex?.call(i);
      await play(assets[i]);
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    stops++;
    if (isPlaying) _current!.complete();
  }

  @override
  Future<void> dispose() async {}
}

class FakeSfxPlayer implements SfxPlayer {
  final played = <String>[];
  final preloaded = <String>[];
  bool fail = false;

  @override
  Future<void> preload(Iterable<String> assets) async {
    if (fail) throw Exception('preload failed');
    preloaded.addAll(assets);
  }

  @override
  Future<void> play(String asset) async {
    if (fail) throw Exception('sfx failed');
    played.add(asset);
  }

  @override
  Future<void> dispose() async {}
}

class FakeMusicPlayer implements MusicPlayer {
  String? track;
  bool playing = false;
  double volume = 0;
  final volumes = <double>[];

  @override
  Future<void> start(String asset, {required double volume}) async {
    track = asset;
    playing = true;
    this.volume = volume;
    volumes.add(volume);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    volumes.add(volume);
  }

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> resume() async => playing = true;

  @override
  Future<void> stop() async {
    playing = false;
    track = null;
  }

  @override
  Future<void> dispose() async {}
}

/// A full set of fake channels.
class FakeAudio {
  final voice = FakeVoicePlayer();
  final sfx = FakeSfxPlayer();
  final music = FakeMusicPlayer();

  AudioChannels get channels => (voice: voice, sfx: sfx, music: music);

  List<String> get sfxNames => [
    for (final a in sfx.played) Sfx.values.firstWhere((s) => s.asset == a).name,
  ];
}
