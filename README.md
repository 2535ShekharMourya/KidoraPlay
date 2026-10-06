# Kidoraplay

A playful learning app for Indian preschoolers (ages 1–6): numbers, ABC,
Hindi letters (अ से अनार), animals, birds, fruits, vegetables, colours,
shapes, vehicles, body parts, family, days, months and opposites, in
English and Hindi, with Kido the baby elephant as guide. Android first.

Also: Kido's daily path (5 steps a day, no streaks), 10 read-aloud
stories, 7 rhymes, finger tracing, quiz games, and toys (Kido's Room,
Tap & Play, Pairs, Music, Colouring). Classes: Baby (1–3), Nursery, LKG,
UKG. Parents get a progress report and a privacy policy (English +
Hindi, also in [docs/privacy-policy.md](docs/privacy-policy.md)).

Everything the app needs is in this repository: every picture, voice
clip, sound, font and content file is under `assets/`, and package
versions are locked in `pubspec.lock`. A fresh clone builds and runs the
same app with no other downloads besides Flutter's own packages.

The product rules (child safety, ads, design, build order) are in
[CLAUDE.md](CLAUDE.md). Read them before changing anything.

## Requirements

| Tool | Version used | Notes |
| --- | --- | --- |
| Flutter | 3.47.6 (stable) | Dart 3.13 |
| Android SDK | API 36 platform, build-tools 36 | via Android Studio or `sdkmanager` |
| Java (JDK) | 17 or newer | Gradle 9.3, AGP 9.1, Kotlin 2.4 |

Check your setup with `flutter doctor`.

## Run it

```bash
flutter pub get
flutter run            # on a connected Android phone or emulator
```

## Build an APK for a phone

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64,android-arm
```

Install `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` on the
phone (use `app-armeabi-v7a-release.apk` for very old phones).

- **Ads:** a release build shows no ads unless it has real AdMob IDs (see
  below). To see Google's *test* ads on a phone, add
  `--dart-define=ADS_TEST=true`.
- **Signing:** release builds are signed with the local debug key for
  now (each machine has its own), so an APK built on another computer
  installs as a different signer: uninstall the old app first. Real
  Play Store signing comes with release prep.

## Real ads (AdMob)

IDs are never committed. Put the app ID in `android/local.properties`:

```properties
admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

and pass the interstitial unit when building:

```bash
flutter build apk --release --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
```

Ads are child-directed (G-rated), only at natural breaks (after a
finished section, game, tracing or balloon party), never in the first
3 minutes, at least 4 minutes apart, after Kido's break screen, and never
for premium users. The advertising ID and ad-tracking permissions are
removed from the manifest.

## Tests

```bash
flutter analyze
flutter test
```

`test/content/content_repository_test.dart` checks that every picture
and voice file the content refers to exists.

Screenshots of every screen at three device sizes (no phone needed):

```bash
flutter test test/screenshots --dart-define=SCREENSHOTS=true
# → build/screenshots/<size>/<screen>.png
```

## Content tools (optional)

The finished content is already in `assets/`. These Python tools only
matter to **change** it (Python 3.12, `ffmpeg` on the PATH,
`pip install edge-tts Pillow SpeechRecognition`; they need internet):

| Tool | Makes |
| --- | --- |
| `tool/make_items.py` | `assets/content/items_*.json` (all words, facts, levels) |
| `tool/make_voice.py` | English and Hindi voice clips (edge-tts, Indian voices) |
| `tool/make_photos.py` | real photos from Wikimedia Commons + `PHOTO_CREDITS.md` |
| `tool/make_pictures.py` | 3D illustrations (Noto Emoji) and drawn cards |
| `tool/make_sounds.py` | real animal/vehicle sounds + `ATTRIBUTION.md` |
| `tool/make_tracing.py` | tracing strokes for A–Z and 0–9 |
| `tool/make_notes.py` | xylophone notes (music toy, rhyme tunes) |
| `tool/make_stories.py` | the 10 picture stories + their pictures |
| `tool/make_rhymes.py` | the rhymes (public-domain / original only) + pictures |

Typical change: edit `tool/make_items.py`, then run `make_items.py`,
`make_voice.py` (only new or changed lines are recorded) and the tests.

> The edge-tts voices are for development only and are not licensed for
> a store release; replace them with licensed recordings before
> publishing.

## Licences

Photos: Wikimedia Commons (see `assets/images/PHOTO_CREDITS.md`).
Sounds: see `assets/audio/ATTRIBUTION.md`. Illustrations: Noto Emoji
(see `assets/images/NOTICE-noto-emoji.txt`). Font: Baloo 2 (OFL,
`assets/fonts/OFL.txt`). All are listed in the app's Parent Area.
