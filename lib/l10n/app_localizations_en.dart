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

  @override
  String get toyTapPlay => 'Tap & Play';

  @override
  String get toyMemory => 'Pairs';

  @override
  String get memoryCard => 'Card';

  @override
  String get toyMusic => 'Music';

  @override
  String get levelBaby => 'Baby';

  @override
  String get progressReport => 'Progress report';

  @override
  String progressSummary(int learned, int total) {
    return '$learned of $total words learned';
  }

  @override
  String progressSectionsDone(int done, int total) {
    return '$done of $total sections complete';
  }

  @override
  String progressNext(String section) {
    return 'Try next: $section';
  }

  @override
  String get progressPrivacy =>
      'Progress is saved only on this phone. Nothing is sent anywhere.';

  @override
  String get todayPath => 'Today';

  @override
  String pathStep(int n) {
    return 'Step $n';
  }

  @override
  String get stories => 'Stories';

  @override
  String get storyTheEnd => 'The End';

  @override
  String get storyAgain => 'Read again';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyBody =>
      'Last updated: 6 October 2026\n\nKidoraplay is a learning app for young children (ages 1–6), used with a parent.\n\nWhat we collect\nNothing. Kidoraplay does not ask for or collect any personal information: no name, age, email, phone number, photos, voice, location or contacts. There is no login. The app does not use the microphone or camera.\n\nWhat stays on your phone\nYour child\'s progress (stickers, today\'s path), the class you choose and your settings are saved only on this phone. They are never sent to us or anyone else. Uninstalling the app deletes them. You can also reset progress in the Parent Area.\n\nNo tracking\nKidoraplay has no analytics, tracking or crash-reporting tools. The advertising ID permission is removed from the app.\n\nAds (free version)\nThe free version shows a short full-screen ad only at natural breaks (after a finished section, game, story or tracing), never in the first minutes of play, at least 4 minutes apart, and after a \"Kido is taking a break\" screen. Ads come from Google AdMob in child-directed mode: they are non-personalised and limited to general-audience (G-rated) content. To show and count an ad, Google may process technical information such as the device\'s IP address and type, under Google\'s own privacy policy (policies.google.com/privacy). Ads cannot be clicked by accident in the play area, and there are no banners.\n\nPurchases\nPremium plans (no ads) are bought through Google Play. Payment details go to Google, not to us. Purchases are only possible in the Parent Area, behind a parental gate.\n\nParental gate\nSettings, purchases and anything outside learning are behind a parental gate that a young child cannot pass.\n\nChildren\'s privacy\nKidoraplay is designed for children and follows Google Play\'s Families policy and India\'s Digital Personal Data Protection Act, 2023. Because we collect no personal data, no parental consent for data processing is needed.\n\nChanges\nIf this policy changes, the new version will be in the app and on our store listing, with a new date.\n\nContact\nYou can reach us at the email address on Kidoraplay\'s Google Play store page.';
}
