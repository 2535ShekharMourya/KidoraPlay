import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import '../theme/app_tokens.dart';
import 'audio_players.dart';
import 'platform_audio_players.dart';

/// Short sound effects.
enum Sfx {
  tap,
  pop,
  sparkle,
  cheer,
  whoosh,
  oops;

  String get asset => 'assets/audio/sfx/$name.m4a';
}

abstract final class AudioAssets {
  static const homeMusic = 'assets/audio/music/home_loop.m4a';
}

/// Three channels that never step on each other:
///
/// - **Voice**: one line at a time. A new line (or sequence) stops the old
///   one; nothing is ever queued.
/// - **SFX**: low-latency, may overlap, mixes with voice.
/// - **Music**: soft loop, ducked while Kido speaks.
///
/// Every failure is swallowed and logged; the child never sees an error and
/// the UI keeps working without sound.
class AudioService {
  AudioService({
    required this._voice,
    required this._sfx,
    required this._music,
    this._settings = const AppSettings(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final VoicePlayer _voice;
  final SfxPlayer _sfx;
  final MusicPlayer _music;
  final DateTime Function() _clock;
  AppSettings _settings;

  int _voiceToken = 0;
  bool _voiceActive = false;
  String? _lastVoiceKey;
  DateTime? _lastVoiceAt;
  bool _musicPlaying = false;
  bool _paused = false;

  bool get isSpeaking => _voiceActive;

  // ---------------------------------------------------------------- voice

  /// Plays one voice clip. Returns true if it played to the end.
  Future<bool> playVoice(String asset) => playVoiceSequence([asset]);

  /// Plays clips back to back (spelling letters, stitched Kido lines).
  /// [onSegment] is called with each index just before it plays, e.g. to
  /// light up the matching letter tile.
  ///
  /// Returns true if the whole sequence played; false if it was interrupted,
  /// debounced, muted or failed.
  Future<bool> playVoiceSequence(
    List<String> assets, {
    void Function(int index)? onSegment,
    Duration gap = Duration.zero,
  }) async {
    if (assets.isEmpty || !_settings.soundEnabled || _paused) return false;

    // Toddler mashing: ignore an identical request within the debounce time.
    final key = assets.join('|');
    final now = _clock();
    if (key == _lastVoiceKey &&
        _lastVoiceAt != null &&
        now.difference(_lastVoiceAt!) < AppDurations.tapDebounce) {
      return false;
    }
    _lastVoiceKey = key;
    _lastVoiceAt = now;

    final token = ++_voiceToken;
    if (_voiceActive) await _safe(_voice.stop, 'stop voice');
    if (token != _voiceToken) return false;

    _voiceActive = true;
    _setDucked(true);
    try {
      for (var i = 0; i < assets.length; i++) {
        if (token != _voiceToken) return false;
        onSegment?.call(i);
        await _voice.play(assets[i]);
        if (gap > Duration.zero && i < assets.length - 1) {
          await Future<void>.delayed(gap);
        }
      }
      return token == _voiceToken;
    } catch (e, s) {
      _log('voice', e, s);
      return false;
    } finally {
      if (token == _voiceToken) {
        _voiceActive = false;
        _setDucked(false);
      }
    }
  }

  Future<void> stopVoice() async {
    _voiceToken++;
    if (!_voiceActive) return;
    _voiceActive = false;
    _setDucked(false);
    await _safe(_voice.stop, 'stop voice');
  }

  // ---------------------------------------------------------------- sfx

  void playSfx(Sfx sfx) {
    if (!_settings.soundEnabled || _paused) return;
    unawaited(_safe(() => _sfx.play(sfx.asset), 'sfx ${sfx.name}'));
  }

  /// Loads sound effects into memory so they play instantly on tap.
  Future<void> preloadSfx([Iterable<Sfx> sfx = Sfx.values]) =>
      _safe(() => _sfx.preload(sfx.map((s) => s.asset)), 'preload sfx');

  // ---------------------------------------------------------------- music

  double get _musicVolume => _voiceActive
      ? AudioLevels.music * AudioLevels.duckFactor
      : AudioLevels.music;

  void _setDucked(bool ducked) {
    if (!_musicPlaying) return;
    unawaited(_safe(() => _music.setVolume(_musicVolume), 'duck music'));
  }

  Future<void> _syncMusic() async {
    final want =
        _settings.soundEnabled && _settings.musicEnabled && !_paused;
    if (want && !_musicPlaying) {
      _musicPlaying = true;
      await _safe(
        () => _music.start(AudioAssets.homeMusic, volume: _musicVolume),
        'start music',
      );
    } else if (!want && _musicPlaying) {
      _musicPlaying = false;
      await _safe(_music.stop, 'stop music');
    }
  }

  // ---------------------------------------------------------------- state

  /// Applies parent settings: muting stops everything immediately.
  Future<void> applySettings(AppSettings settings) async {
    _settings = settings;
    if (!settings.soundEnabled) await stopVoice();
    await _syncMusic();
  }

  /// App went to the background: silence everything.
  Future<void> pauseAll() async {
    _paused = true;
    await stopVoice();
    if (_musicPlaying) await _safe(_music.pause, 'pause music');
  }

  /// App came back: resume music if it was on.
  Future<void> resumeAll() async {
    _paused = false;
    if (_musicPlaying) {
      await _safe(_music.resume, 'resume music');
    } else {
      await _syncMusic();
    }
  }

  Future<void> dispose() async {
    _voiceToken++;
    await Future.wait([
      _safe(_voice.dispose, 'dispose voice'),
      _safe(_sfx.dispose, 'dispose sfx'),
      _safe(_music.dispose, 'dispose music'),
    ]);
  }

  Future<void> _safe(Future<void> Function() action, String what) async {
    try {
      await action();
    } catch (e, s) {
      _log(what, e, s);
    }
  }

  void _log(String what, Object e, StackTrace s) =>
      debugPrint('AudioService: $what failed: $e');
}

/// Mix levels (0–1).
abstract final class AudioLevels {
  static const music = 0.35;

  /// Music drops to 30% of its level while Kido speaks.
  static const duckFactor = 0.3;
}

/// The three platform players. Tests override this with fakes.
final audioChannelsProvider = Provider<AudioChannels>(
  (ref) => (
    voice: JustAudioVoicePlayer(),
    sfx: AudioplayersSfxPlayer(),
    music: JustAudioMusicPlayer(),
  ),
);

typedef AudioChannels = ({
  VoicePlayer voice,
  SfxPlayer sfx,
  MusicPlayer music,
});

/// The app-wide audio service. Follows settings changes and goes silent
/// while the app is in the background.
final audioServiceProvider = Provider<AudioService>((ref) {
  final channels = ref.watch(audioChannelsProvider);
  final service = AudioService(
    voice: channels.voice,
    sfx: channels.sfx,
    music: channels.music,
    settings: ref.read(settingsProvider),
  );
  ref.listen<AppSettings>(
    settingsProvider,
    (_, next) => unawaited(service.applySettings(next)),
    fireImmediately: true,
  );
  final lifecycle = AppLifecycleListener(
    onHide: () => unawaited(service.pauseAll()),
    onShow: () => unawaited(service.resumeAll()),
  );
  ref.onDispose(() {
    lifecycle.dispose();
    unawaited(service.dispose());
  });
  return service;
});
