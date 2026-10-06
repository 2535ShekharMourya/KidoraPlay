import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/parent/progress_report_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  testWidgets('shows learned words, sections and a tip', (tester) async {
    await pumpApp(
      tester,
      const ProgressReportScreen(),
      catalog: catalog,
      store: LocalStore.inMemory({
        SettingsKeys.language: 'en',
        SettingsKeys.level: 'baby',
        // All five baby numbers, and one animal.
        'progress.learned': ['one', 'two', 'three', 'four', 'five', 'cow'],
      }),
    );
    await tester.pump();

    expect(find.textContaining('6 of '), findsOneWidget);
    expect(find.text('1 of 8 sections complete'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget); // Numbers
    expect(find.text('1 / 15'), findsOneWidget); // Animals
    // The tip: carry on with the started section (Animals), not the
    // finished one (Numbers) or one not started yet.
    expect(find.text('Try next: Animals'), findsOneWidget);
    // Every section of the class is listed.
    await tester.scrollUntilVisible(find.text('Body'), 200);
    expect(find.text('0 / 11'), findsOneWidget);
  });
}
