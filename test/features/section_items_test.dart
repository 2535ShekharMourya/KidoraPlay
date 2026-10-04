import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/section_grid/section_items.dart';

import '../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  setUpAll(() async => catalog = await loadTestCatalog());

  Future<ProviderContainer> containerFor(String level) async {
    final c = ProviderContainer(
      overrides: testOverrides(
        catalog: catalog,
        store: LocalStore.inMemory({SettingsKeys.level: level}),
      ),
    );
    addTearDown(c.dispose);
    await c.read(contentCatalogProvider.future);
    return c;
  }

  test('numberRowOf groups numbers in tens', () {
    expect(numberRowOf(1), 1);
    expect(numberRowOf(10), 1);
    expect(numberRowOf(11), 2);
    expect(numberRowOf(21), 3);
    expect(numberRowOf(100), 10);
  });

  test('Nursery sees numbers 1–20 (two rows)', () async {
    final c = await containerFor('nursery');
    expect(c.read(numberRowsProvider), [1, 2]);
    final items =
        c.read(scopeItemsProvider((section: SectionId.numbers, row: null)));
    expect(items.map((i) => i.number), [for (var n = 1; n <= 20; n++) n]);
  });

  test('LKG sees all ten rows; a row holds its ten numbers', () async {
    final c = await containerFor('lkg');
    expect(c.read(numberRowsProvider), [for (var r = 1; r <= 10; r++) r]);
    final row3 =
        c.read(scopeItemsProvider((section: SectionId.numbers, row: 3)));
    expect(row3.map((i) => i.number), [for (var n = 21; n <= 30; n++) n]);
    expect(row3.first.wordEn, 'Twenty-one');
  });

  test('a whole section keeps content order', () async {
    final c = await containerFor('ukg');
    final abc = c.read(scopeItemsProvider((section: SectionId.abc, row: null)));
    expect(abc.map((i) => i.letter).join(), 'ABCDEFGHIJ');
  });
}
