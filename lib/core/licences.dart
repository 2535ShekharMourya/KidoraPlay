import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds credits for bundled third-party content to Flutter's licence
/// registry, so they appear on the licences page in the Parent Area.
/// CC BY / CC BY-SA sounds require this attribution.
void registerContentLicences() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Animal and bird sounds (Wikimedia Commons)',
    ], await rootBundle.loadString('assets/audio/ATTRIBUTION.md'));
    yield LicenseEntryWithLineBreaks(const [
      'Noto Emoji pictures',
    ], await rootBundle.loadString('assets/images/NOTICE-noto-emoji.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Baloo 2 font',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
}
