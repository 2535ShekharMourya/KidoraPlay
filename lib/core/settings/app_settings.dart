import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/level.dart';
import '../storage/local_store.dart';

/// Which language(s) Kido speaks. "both" plays English then Hindi.
enum LanguageMode {
  en,
  hi,
  both;

  List<ContentLanguage> get languages => switch (this) {
        LanguageMode.en => const [ContentLanguage.en],
        LanguageMode.hi => const [ContentLanguage.hi],
        LanguageMode.both => const [ContentLanguage.en, ContentLanguage.hi],
      };
}

abstract final class SettingsKeys {
  static const sound = 'settings.sound_enabled';
  static const music = 'settings.music_enabled';
  static const vibration = 'settings.vibration_enabled';
  static const language = 'settings.language';
  static const level = 'settings.level';
}

/// Parent-controlled settings, stored on the device only.
@immutable
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    // Background music is off by default (gentler for 2–3-year-olds).
    this.musicEnabled = false,
    this.vibrationEnabled = true,
    this.language = LanguageMode.en,
    // Shows 1–100 and all Phase 1 sections; parents change it in the
    // Parent Area.
    this.level = Level.lkg,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final LanguageMode language;

  /// Preschool class; filters which sections and items appear.
  final Level level;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    LanguageMode? language,
    Level? level,
  }) =>
      AppSettings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        language: language ?? this.language,
        level: level ?? this.level,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.soundEnabled == soundEnabled &&
      other.musicEnabled == musicEnabled &&
      other.vibrationEnabled == vibrationEnabled &&
      other.language == language &&
      other.level == level;

  @override
  int get hashCode =>
      Object.hash(soundEnabled, musicEnabled, vibrationEnabled, language, level);
}

class SettingsNotifier extends Notifier<AppSettings> {
  LocalStore get _store => ref.read(localStoreProvider);

  @override
  AppSettings build() {
    final store = ref.watch(localStoreProvider);
    const d = AppSettings();
    return AppSettings(
      soundEnabled: store.getBool(SettingsKeys.sound, fallback: d.soundEnabled),
      musicEnabled: store.getBool(SettingsKeys.music, fallback: d.musicEnabled),
      vibrationEnabled:
          store.getBool(SettingsKeys.vibration, fallback: d.vibrationEnabled),
      language: LanguageMode.values.asNameMap()[
              store.getString(SettingsKeys.language)] ??
          d.language,
      level: Level.values.asNameMap()[store.getString(SettingsKeys.level)] ??
          d.level,
    );
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _store.setBool(SettingsKeys.sound, value: value);
  }

  Future<void> setMusicEnabled(bool value) async {
    state = state.copyWith(musicEnabled: value);
    await _store.setBool(SettingsKeys.music, value: value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    state = state.copyWith(vibrationEnabled: value);
    await _store.setBool(SettingsKeys.vibration, value: value);
  }

  Future<void> setLanguage(LanguageMode value) async {
    state = state.copyWith(language: value);
    await _store.setString(SettingsKeys.language, value.name);
  }

  Future<void> setLevel(Level value) async {
    state = state.copyWith(level: value);
    await _store.setString(SettingsKeys.level, value.name);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
