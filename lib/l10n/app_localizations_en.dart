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
}
