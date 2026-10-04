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
