import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Kidoraplay'**
  String get appTitle;

  /// No description provided for @sectionNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get sectionNumbers;

  /// No description provided for @sectionAbc.
  ///
  /// In en, this message translates to:
  /// **'ABC'**
  String get sectionAbc;

  /// No description provided for @sectionAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get sectionAnimals;

  /// No description provided for @sectionBirds.
  ///
  /// In en, this message translates to:
  /// **'Birds'**
  String get sectionBirds;

  /// Semantics label for the big back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Semantics label for a row of numbers, e.g. 1 to 10
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String numberRow(int from, int to);

  /// Semantics label for the place-value picture
  ///
  /// In en, this message translates to:
  /// **'{tens} tens and {ones} ones'**
  String placeValue(int tens, int ones);

  /// No description provided for @stickerBook.
  ///
  /// In en, this message translates to:
  /// **'Sticker book'**
  String get stickerBook;

  /// No description provided for @parentArea.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parentArea;

  /// No description provided for @parentGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups only'**
  String get parentGateTitle;

  /// No description provided for @gateHold.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the button for 3 seconds'**
  String get gateHold;

  /// No description provided for @gateHoldButton.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get gateHoldButton;

  /// No description provided for @gateTapNumber.
  ///
  /// In en, this message translates to:
  /// **'Tap the number {word}'**
  String gateTapNumber(String word);

  /// Number words 1 to 9, comma separated, for the parent gate
  ///
  /// In en, this message translates to:
  /// **'one,two,three,four,five,six,seven,eight,nine'**
  String get gateNumberWords;

  /// No description provided for @gateTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Here is a new one.'**
  String get gateTryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settingsClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get settingsClass;

  /// No description provided for @levelNursery.
  ///
  /// In en, this message translates to:
  /// **'Nursery'**
  String get levelNursery;

  /// No description provided for @levelLkg.
  ///
  /// In en, this message translates to:
  /// **'LKG'**
  String get levelLkg;

  /// No description provided for @levelUkg.
  ///
  /// In en, this message translates to:
  /// **'UKG'**
  String get levelUkg;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Kido speaks'**
  String get settingsLanguage;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get langHindi;

  /// No description provided for @langBoth.
  ///
  /// In en, this message translates to:
  /// **'English + हिंदी'**
  String get langBoth;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get settingsMusic;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressStickers.
  ///
  /// In en, this message translates to:
  /// **'{count} stickers collected'**
  String progressStickers(int count);

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start over? All stickers will be removed.'**
  String get resetConfirm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Kidoraplay collects no personal data. Everything stays on this device.'**
  String get privacyNote;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Licences and credits'**
  String get licences;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Kidoraplay Premium'**
  String get plansTitle;

  /// No description provided for @plansEntry.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get plansEntry;

  /// No description provided for @plansEntryFree.
  ///
  /// In en, this message translates to:
  /// **'Remove ads for your child'**
  String get plansEntryFree;

  /// No description provided for @plansPitch.
  ///
  /// In en, this message translates to:
  /// **'Premium removes all ads, now and in future learning packs. One purchase covers this Google account.'**
  String get plansPitch;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime (one-time)'**
  String get planLifetime;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get restorePurchase;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active. Thank you!'**
  String get premiumActive;

  /// No description provided for @premiumThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Premium is now active.'**
  String get premiumThanks;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Your purchase has been restored.'**
  String get restoreDone;

  /// No description provided for @restoreNone.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase was found for this Google account.'**
  String get restoreNone;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not go through. You have not been charged.'**
  String get purchaseFailed;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the payment to finish…'**
  String get purchasePending;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Play is not available right now. Please check your internet connection and try again.'**
  String get storeUnavailable;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically until cancelled. Cancel anytime in Google Play → Payments & subscriptions. The lifetime plan is a single payment.'**
  String get subscriptionTerms;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @gameFindIt.
  ///
  /// In en, this message translates to:
  /// **'Find it'**
  String get gameFindIt;

  /// No description provided for @gameWhoSays.
  ///
  /// In en, this message translates to:
  /// **'Who says?'**
  String get gameWhoSays;

  /// No description provided for @gameCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get gameCount;

  /// No description provided for @gameLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get gameLetters;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @hearAgain.
  ///
  /// In en, this message translates to:
  /// **'Hear again'**
  String get hearAgain;

  /// No description provided for @sectionFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get sectionFruits;

  /// No description provided for @sectionVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get sectionVegetables;

  /// No description provided for @sectionColours.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get sectionColours;

  /// No description provided for @sectionShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get sectionShapes;

  /// No description provided for @sectionVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get sectionVehicles;

  /// No description provided for @sectionHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get sectionHindi;

  /// No description provided for @traceIt.
  ///
  /// In en, this message translates to:
  /// **'Write it'**
  String get traceIt;

  /// No description provided for @traceAgain.
  ///
  /// In en, this message translates to:
  /// **'Write again'**
  String get traceAgain;

  /// No description provided for @adBreak.
  ///
  /// In en, this message translates to:
  /// **'Kido is taking a little break 🐘'**
  String get adBreak;

  /// No description provided for @sectionBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get sectionBody;

  /// No description provided for @sectionFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get sectionFamily;

  /// No description provided for @sectionDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get sectionDays;

  /// No description provided for @sectionMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get sectionMonths;

  /// No description provided for @sectionOpposites.
  ///
  /// In en, this message translates to:
  /// **'Opposites'**
  String get sectionOpposites;

  /// No description provided for @toyTapPlay.
  ///
  /// In en, this message translates to:
  /// **'Tap & Play'**
  String get toyTapPlay;

  /// No description provided for @toyMemory.
  ///
  /// In en, this message translates to:
  /// **'Pairs'**
  String get toyMemory;

  /// No description provided for @memoryCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get memoryCard;

  /// No description provided for @toyMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get toyMusic;

  /// No description provided for @levelBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get levelBaby;

  /// No description provided for @progressReport.
  ///
  /// In en, this message translates to:
  /// **'Progress report'**
  String get progressReport;

  /// No description provided for @progressSummary.
  ///
  /// In en, this message translates to:
  /// **'{learned} of {total} words learned'**
  String progressSummary(int learned, int total);

  /// No description provided for @progressSectionsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} sections complete'**
  String progressSectionsDone(int done, int total);

  /// No description provided for @progressNext.
  ///
  /// In en, this message translates to:
  /// **'Try next: {section}'**
  String progressNext(String section);

  /// No description provided for @progressPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Progress is saved only on this phone. Nothing is sent anywhere.'**
  String get progressPrivacy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
