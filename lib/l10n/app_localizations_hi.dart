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
}
