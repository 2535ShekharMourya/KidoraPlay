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

  @override
  String get plansTitle => 'किडोराप्ले प्रीमियम';

  @override
  String get plansEntry => 'प्रीमियम';

  @override
  String get plansEntryFree => 'अपने बच्चे के लिए विज्ञापन हटाएँ';

  @override
  String get plansPitch =>
      'प्रीमियम सभी विज्ञापन हटा देता है, अभी और आने वाले सभी पाठों में भी। एक खरीद इस Google खाते के लिए काम करती है।';

  @override
  String get planMonthly => 'मासिक';

  @override
  String get planYearly => 'वार्षिक';

  @override
  String get planLifetime => 'आजीवन (एक बार)';

  @override
  String get buy => 'खरीदें';

  @override
  String get restorePurchase => 'खरीद वापस लाएँ';

  @override
  String get premiumActive => 'प्रीमियम चालू है। धन्यवाद!';

  @override
  String get premiumThanks => 'धन्यवाद! प्रीमियम अब चालू है।';

  @override
  String get restoreDone => 'आपकी खरीद वापस आ गई है।';

  @override
  String get restoreNone => 'इस Google खाते पर कोई पिछली खरीद नहीं मिली।';

  @override
  String get purchaseFailed => 'खरीद पूरी नहीं हुई। आपसे पैसे नहीं लिए गए।';

  @override
  String get purchasePending => 'भुगतान पूरा होने का इंतज़ार है…';

  @override
  String get storeUnavailable =>
      'Google Play अभी उपलब्ध नहीं है। कृपया इंटरनेट जाँचें और फिर कोशिश करें।';

  @override
  String get subscriptionTerms =>
      'सदस्यता रद्द करने तक अपने आप नवीनीकृत होती है। Google Play → भुगतान और सदस्यता में कभी भी रद्द करें। आजीवन प्लान एक बार का भुगतान है।';

  @override
  String get games => 'खेल';

  @override
  String get gameFindIt => 'ढूँढो';

  @override
  String get gameWhoSays => 'किसकी आवाज़?';

  @override
  String get gameCount => 'गिनो';

  @override
  String get gameLetters => 'अक्षर';

  @override
  String get playAgain => 'फिर से खेलो';

  @override
  String get hearAgain => 'फिर से सुनो';

  @override
  String get sectionFruits => 'फल';

  @override
  String get sectionVegetables => 'सब्ज़ियाँ';

  @override
  String get sectionColours => 'रंग';

  @override
  String get sectionShapes => 'आकार';

  @override
  String get sectionVehicles => 'वाहन';

  @override
  String get sectionHindi => 'हिंदी';

  @override
  String get traceIt => 'लिखो';

  @override
  String get traceAgain => 'फिर से लिखो';

  @override
  String get adBreak => 'किडो थोड़ा आराम कर रहा है 🐘';

  @override
  String get sectionBody => 'शरीर';

  @override
  String get sectionFamily => 'परिवार';

  @override
  String get sectionDays => 'दिन';

  @override
  String get sectionMonths => 'महीने';

  @override
  String get sectionOpposites => 'उल्टे शब्द';

  @override
  String get toyTapPlay => 'छुओ और खेलो';

  @override
  String get toyMemory => 'जोड़ी';

  @override
  String get memoryCard => 'कार्ड';
}
