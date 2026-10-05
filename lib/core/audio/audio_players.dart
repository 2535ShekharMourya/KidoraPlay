/// Platform-neutral audio channel interfaces used by AudioService.
/// Real implementations live in `platform_audio_players.dart`; tests use
/// fakes.
library;

/// One voice at a time (Kido, item names, letters).
abstract interface class VoicePlayer {
  /// Plays [asset] and completes when it finishes or is stopped.
  /// Throws if the asset cannot be played.
  Future<void> play(String asset);

  /// Plays [assets] back to back with no gaps (a stitched sentence like
  /// "Tap the" + "apple"), calling [onIndex] as each one starts. Completes
  /// when the last one finishes or playback is stopped.
  Future<void> playAll(
    List<String> assets, {
    void Function(int index)? onIndex,
  });

  Future<void> stop();

  Future<void> dispose();
}

/// Low-latency, overlapping short sounds.
abstract interface class SfxPlayer {
  /// Loads [assets] into memory so they play instantly.
  Future<void> preload(Iterable<String> assets);

  Future<void> play(String asset);

  Future<void> dispose();
}

/// Looping background music.
abstract interface class MusicPlayer {
  Future<void> start(String asset, {required double volume});

  Future<void> setVolume(double volume);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}
