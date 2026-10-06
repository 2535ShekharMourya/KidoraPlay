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

  @override
  String get toyMusic => 'म्यूज़िक';

  @override
  String get levelBaby => 'बेबी';

  @override
  String get progressReport => 'प्रगति रिपोर्ट';

  @override
  String progressSummary(int learned, int total) {
    return '$total में से $learned शब्द सीखे';
  }

  @override
  String progressSectionsDone(int done, int total) {
    return '$total में से $done भाग पूरे';
  }

  @override
  String progressNext(String section) {
    return 'अगला आज़माएँ: $section';
  }

  @override
  String get progressPrivacy =>
      'प्रगति सिर्फ़ इसी फ़ोन में सेव होती है। कुछ भी कहीं नहीं भेजा जाता।';

  @override
  String get todayPath => 'आज';

  @override
  String pathStep(int n) {
    return 'कदम $n';
  }

  @override
  String get stories => 'कहानियाँ';

  @override
  String get storyTheEnd => 'कहानी ख़त्म';

  @override
  String get storyAgain => 'फिर से पढ़ो';

  @override
  String get privacyPolicy => 'प्राइवेसी पॉलिसी';

  @override
  String get privacyPolicyBody =>
      'अंतिम अपडेट: 6 October 2026\n\nकिडोराप्ले छोटे बच्चों (1–6 साल) के लिए सीखने का ऐप है, जिसे माता-पिता के साथ इस्तेमाल किया जाता है।\n\nहम क्या लेते हैं\nकुछ नहीं। किडोराप्ले कोई निजी जानकारी नहीं माँगता और न ही लेता है: न नाम, न उम्र, न ईमेल, न फ़ोन नंबर, न फ़ोटो, न आवाज़, न लोकेशन, न कॉन्टैक्ट। कोई लॉगिन नहीं है। ऐप माइक्रोफ़ोन या कैमरा इस्तेमाल नहीं करता।\n\nआपके फ़ोन में क्या रहता है\nबच्चे की प्रगति (स्टिकर, आज का रास्ता), चुनी गई क्लास और सेटिंग्स सिर्फ़ इसी फ़ोन में सेव होती हैं। ये कभी हमें या किसी और को नहीं भेजी जातीं। ऐप हटाने पर ये मिट जाती हैं। आप पैरेंट एरिया में प्रगति रीसेट भी कर सकते हैं।\n\nकोई ट्रैकिंग नहीं\nकिडोराप्ले में कोई एनालिटिक्स, ट्रैकिंग या क्रैश-रिपोर्टिंग टूल नहीं है। विज्ञापन आईडी की अनुमति ऐप से हटा दी गई है।\n\nविज्ञापन (फ़्री वर्ज़न)\nफ़्री वर्ज़न में छोटा फ़ुल-स्क्रीन विज्ञापन सिर्फ़ स्वाभाविक ब्रेक पर आता है (कोई भाग, खेल, कहानी या ट्रेसिंग पूरी होने के बाद), खेल के पहले कुछ मिनटों में कभी नहीं, कम से कम 4 मिनट के अंतर पर, और \"किडो थोड़ा आराम कर रहा है\" स्क्रीन के बाद। विज्ञापन Google AdMob से बच्चों वाले मोड में आते हैं: ये व्यक्तिगत नहीं होते और सिर्फ़ सबके लिए उपयुक्त (G-रेटेड) होते हैं। विज्ञापन दिखाने और गिनने के लिए Google डिवाइस की तकनीकी जानकारी, जैसे IP पता और डिवाइस का प्रकार, अपनी प्राइवेसी पॉलिसी (policies.google.com/privacy) के तहत इस्तेमाल कर सकता है। खेलने वाली जगह पर गलती से विज्ञापन नहीं छुआ जा सकता, और कोई बैनर नहीं है।\n\nख़रीदारी\nप्रीमियम प्लान (बिना विज्ञापन) Google Play से ख़रीदे जाते हैं। भुगतान की जानकारी Google के पास जाती है, हमारे पास नहीं। ख़रीदारी सिर्फ़ पैरेंट एरिया में, पैरेंटल गेट के पीछे हो सकती है।\n\nपैरेंटल गेट\nसेटिंग्स, ख़रीदारी और सीखने के अलावा सब कुछ एक पैरेंटल गेट के पीछे है, जिसे छोटा बच्चा पार नहीं कर सकता।\n\nबच्चों की प्राइवेसी\nकिडोराप्ले बच्चों के लिए बना है और Google Play की फ़ैमिली पॉलिसी और भारत के डिजिटल पर्सनल डेटा प्रोटेक्शन एक्ट, 2023 का पालन करता है। हम कोई निजी डेटा नहीं लेते, इसलिए डेटा के लिए माता-पिता की सहमति की ज़रूरत नहीं है।\n\nबदलाव\nअगर यह पॉलिसी बदलती है, तो नया वर्ज़न नई तारीख़ के साथ ऐप में और हमारे स्टोर पेज पर होगा।\n\nसंपर्क\nआप किडोराप्ले के Google Play स्टोर पेज पर दिए ईमेल पते पर हमसे संपर्क कर सकते हैं।';

  @override
  String get toyKidoRoom => 'किडो';

  @override
  String get roomFeed => 'किडो को खिलाओ';

  @override
  String get roomBath => 'नहाना';

  @override
  String get roomHat => 'टोपी';

  @override
  String get roomKido => 'किडो';

  @override
  String get rhymes => 'कविताएँ';

  @override
  String get rhymeAgain => 'फिर से गाओ';
}
