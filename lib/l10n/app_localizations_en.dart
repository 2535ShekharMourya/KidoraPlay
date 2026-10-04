// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kidoraplay';

  @override
  String get sectionNumbers => 'Numbers';

  @override
  String get sectionAbc => 'ABC';

  @override
  String get sectionAnimals => 'Animals';

  @override
  String get sectionBirds => 'Birds';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String numberRow(int from, int to) {
    return '$from to $to';
  }

  @override
  String placeValue(int tens, int ones) {
    return '$tens tens and $ones ones';
  }

  @override
  String get stickerBook => 'Sticker book';

  @override
  String get parentArea => 'Parents';

  @override
  String get parentGateTitle => 'Grown-ups only';

  @override
  String get gateHold => 'Press and hold the button for 3 seconds';

  @override
  String get gateHoldButton => 'Hold';

  @override
  String gateTapNumber(String word) {
    return 'Tap the number $word';
  }

  @override
  String get gateNumberWords => 'one,two,three,four,five,six,seven,eight,nine';

  @override
  String get gateTryAgain => 'Not quite. Here is a new one.';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsClass => 'Class';

  @override
  String get levelNursery => 'Nursery';

  @override
  String get levelLkg => 'LKG';

  @override
  String get levelUkg => 'UKG';

  @override
  String get settingsLanguage => 'Kido speaks';

  @override
  String get langEnglish => 'English';

  @override
  String get langHindi => 'हिंदी';

  @override
  String get langBoth => 'English + हिंदी';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsMusic => 'Background music';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get progressTitle => 'Progress';

  @override
  String progressStickers(int count) {
    return '$count stickers collected';
  }

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetConfirm => 'Start over? All stickers will be removed.';

  @override
  String get reset => 'Reset';

  @override
  String get privacyNote =>
      'Kidoraplay collects no personal data. Everything stays on this device.';

  @override
  String get licences => 'Licences and credits';

  @override
  String get aboutTitle => 'About';
}
