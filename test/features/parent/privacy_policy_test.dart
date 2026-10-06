import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:kidoraplay/features/parent/privacy_policy_screen.dart';
import 'package:kidoraplay/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('English policy: headings and the key promises', (tester) async {
    await pumpApp(tester, const PrivacyPolicyScreen());
    expect(find.text('What we collect'), findsOneWidget);
    expect(find.textContaining('does not ask for or collect'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('child-directed'), 200);
    expect(find.text('Ads (free version)'), findsOneWidget);
  });

  test('a Hindi phone gets the policy in Hindi', () {
    final hi = lookupAppLocalizations(const Locale('hi'));
    expect(hi.privacyPolicy, 'प्राइवेसी पॉलिसी');
    expect(hi.privacyPolicyBody, contains('हम क्या लेते हैं'));
    expect(hi.privacyPolicyBody, contains('कोई निजी जानकारी नहीं'));
  });

  test('the store-listing copy matches the app (same headings)', () {
    final doc = File('docs/privacy-policy.md').readAsStringSync();
    for (final h in [
      'What we collect',
      'Ads (free version)',
      'Purchases',
      'हम क्या लेते हैं',
    ]) {
      expect(doc, contains('## $h'), reason: h);
    }
  });
}
