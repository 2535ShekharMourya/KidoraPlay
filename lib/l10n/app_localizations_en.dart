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

  @override
  String get plansTitle => 'Kidoraplay Premium';

  @override
  String get plansEntry => 'Premium';

  @override
  String get plansEntryFree => 'Remove ads for your child';

  @override
  String get plansPitch =>
      'Premium removes all ads, now and in future learning packs. One purchase covers this Google account.';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planLifetime => 'Lifetime (one-time)';

  @override
  String get buy => 'Buy';

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get premiumActive => 'Premium is active. Thank you!';

  @override
  String get premiumThanks => 'Thank you! Premium is now active.';

  @override
  String get restoreDone => 'Your purchase has been restored.';

  @override
  String get restoreNone =>
      'No previous purchase was found for this Google account.';

  @override
  String get purchaseFailed =>
      'The purchase did not go through. You have not been charged.';

  @override
  String get purchasePending => 'Waiting for the payment to finish…';

  @override
  String get storeUnavailable =>
      'Google Play is not available right now. Please check your internet connection and try again.';

  @override
  String get subscriptionTerms =>
      'Subscriptions renew automatically until cancelled. Cancel anytime in Google Play → Payments & subscriptions. The lifetime plan is a single payment.';

  @override
  String get games => 'Games';

  @override
  String get gameFindIt => 'Find it';

  @override
  String get gameWhoSays => 'Who says?';

  @override
  String get gameCount => 'Count';

  @override
  String get gameLetters => 'Letters';

  @override
  String get playAgain => 'Play again';

  @override
  String get hearAgain => 'Hear again';

  @override
  String get sectionFruits => 'Fruits';

  @override
  String get sectionVegetables => 'Vegetables';

  @override
  String get sectionColours => 'Colours';

  @override
  String get sectionShapes => 'Shapes';

  @override
  String get sectionVehicles => 'Vehicles';

  @override
  String get sectionHindi => 'Hindi';

  @override
  String get traceIt => 'Write it';

  @override
  String get traceAgain => 'Write again';

  @override
  String get adBreak => 'Kido is taking a little break 🐘';

  @override
  String get sectionBody => 'Body';

  @override
  String get sectionFamily => 'Family';

  @override
  String get sectionDays => 'Days';

  @override
  String get sectionMonths => 'Months';

  @override
  String get sectionOpposites => 'Opposites';
}
