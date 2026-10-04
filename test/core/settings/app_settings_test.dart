import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';

void main() {
  ProviderContainer containerWith(LocalStore store) {
    final c = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('defaults: sound on, music off, vibration on, both languages', () {
    final settings = containerWith(LocalStore.inMemory())
        .read(settingsProvider);
    expect(settings, const AppSettings());
    expect(settings.soundEnabled, isTrue);
    expect(settings.musicEnabled, isFalse);
    expect(settings.vibrationEnabled, isTrue);
    expect(settings.language, LanguageMode.both);
  });

  test('changes are saved locally and survive a restart', () async {
    final store = LocalStore.inMemory();
    final notifier = containerWith(store).read(settingsProvider.notifier);
    await notifier.setSoundEnabled(false);
    await notifier.setMusicEnabled(true);
    await notifier.setVibrationEnabled(false);
    await notifier.setLanguage(LanguageMode.both);

    final reloaded = containerWith(store).read(settingsProvider);
    expect(
      reloaded,
      const AppSettings(
        soundEnabled: false,
        musicEnabled: true,
        vibrationEnabled: false,
        language: LanguageMode.both,
      ),
    );
  });

  test('unknown stored language falls back to the default', () {
    final store = LocalStore.inMemory({SettingsKeys.language: 'fr'});
    expect(
      containerWith(store).read(settingsProvider).language,
      LanguageMode.both,
    );
  });

  test('"both" speaks English then Hindi', () {
    expect(LanguageMode.both.languages, [
      ContentLanguage.en,
      ContentLanguage.hi,
    ]);
  });
}
