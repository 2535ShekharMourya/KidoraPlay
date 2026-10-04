// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'किडोराप्ले';

  @override
  String get sectionNumbers => 'गिनती';

  @override
  String get sectionAbc => 'एबीसी';

  @override
  String get sectionAnimals => 'जानवर';

  @override
  String get sectionBirds => 'पक्षी';

  @override
  String get back => 'वापस';

  @override
  String get next => 'आगे';

  @override
  String get previous => 'पीछे';

  @override
  String numberRow(int from, int to) {
    return '$from से $to';
  }

  @override
  String placeValue(int tens, int ones) {
    return '$tens दहाई और $ones इकाई';
  }

  @override
  String get stickerBook => 'स्टिकर बुक';

  @override
  String get parentArea => 'अभिभावक';

  @override
  String get parentGateTitle => 'केवल बड़ों के लिए';

  @override
  String get gateHold => 'बटन को 3 सेकंड तक दबाकर रखें';

  @override
  String get gateHoldButton => 'दबाए रखें';

  @override
  String gateTapNumber(String word) {
    return 'संख्या $word चुनें';
  }

  @override
  String get gateNumberWords => 'एक,दो,तीन,चार,पाँच,छह,सात,आठ,नौ';

  @override
  String get gateTryAgain => 'सही नहीं है। यह नया सवाल है।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get settingsClass => 'कक्षा';

  @override
  String get levelNursery => 'नर्सरी';

  @override
  String get levelLkg => 'एलकेजी';

  @override
  String get levelUkg => 'यूकेजी';

  @override
  String get settingsLanguage => 'किडो की भाषा';

  @override
  String get langEnglish => 'English';

  @override
  String get langHindi => 'हिंदी';

  @override
  String get langBoth => 'English + हिंदी';

  @override
  String get settingsSound => 'आवाज़';

  @override
  String get settingsMusic => 'बैकग्राउंड संगीत';

  @override
  String get settingsVibration => 'वाइब्रेशन';

  @override
  String get progressTitle => 'प्रगति';

  @override
  String progressStickers(int count) {
    return '$count स्टिकर मिले';
  }

  @override
  String get resetProgress => 'प्रगति रीसेट करें';

  @override
  String get resetConfirm => 'फिर से शुरू करें? सभी स्टिकर हट जाएँगे।';

  @override
  String get reset => 'रीसेट';

  @override
  String get privacyNote =>
      'किडोराप्ले कोई निजी जानकारी नहीं लेता। सब कुछ इसी फ़ोन में रहता है।';

  @override
  String get licences => 'लाइसेंस और श्रेय';

  @override
  String get aboutTitle => 'जानकारी';
}
