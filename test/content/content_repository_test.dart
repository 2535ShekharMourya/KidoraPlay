import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/kido_line.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/content/repository/content_validator.dart';

/// Serves real bundled assets but lets a test replace one file's text.
class _PatchedBundle extends CachingAssetBundle {
  _PatchedBundle(this.patches);

  final Map<String, String> patches;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      patches[key] ?? rootBundle.loadString(key, cache: cache);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled content', () {
    test('loads and passes validation', () async {
      final repo = ContentRepository(bundle: rootBundle, validate: true);
      final catalog = await repo.load();

      expect(catalog.sections.map((s) => s.id), SectionId.values);
      expect(catalog.itemsFor(SectionId.numbers), hasLength(100));
      expect(catalog.itemsFor(SectionId.abc), hasLength(26));
      expect(catalog.itemsFor(SectionId.animals), hasLength(15));
      expect(catalog.itemsFor(SectionId.birds), hasLength(10));
      expect(catalog.itemsFor(SectionId.fruits), hasLength(12));
      expect(catalog.itemsFor(SectionId.vegetables), hasLength(12));
      expect(catalog.itemsFor(SectionId.colours), hasLength(10));
      expect(catalog.itemsFor(SectionId.shapes), hasLength(8));
      expect(catalog.itemsFor(SectionId.vehicles), hasLength(12));
      expect(catalog.itemsFor(SectionId.hindi), hasLength(45));
      expect(catalog.itemsFor(SectionId.body), hasLength(11));
      expect(catalog.itemsFor(SectionId.family), hasLength(8));
      expect(catalog.itemsFor(SectionId.days), hasLength(7));
      expect(catalog.itemsFor(SectionId.months), hasLength(12));
      expect(catalog.itemsFor(SectionId.opposites), hasLength(16));
      // Opposites come in pairs, each naming the other.
      expect(catalog.itemById('opp_hot')?.factEn, 'Hot! The opposite is cold.');
      expect(
        catalog.itemById('opp_cold')?.factEn,
        'Cold! The opposite is hot.',
      );
      expect(catalog.itemById('day_sunday')?.wordHi, 'रविवार');
      // Every item teaches a fun fact, except numbers.
      for (final item in catalog.allItems) {
        if (item.section == SectionId.numbers ||
            item.section == SectionId.hindi) {
          continue;
        }
        expect(item.factEn, isNotNull, reason: item.id);
      }
      expect(catalog.itemById('peacock')?.wordHi, 'मोर');
      expect(catalog.itemById('seven')?.number, 7);
      for (final event in KidoEvent.all) {
        expect(
          catalog.kidoLines.variants(event, ContentLanguage.en),
          isNotEmpty,
          reason: event,
        );
      }
      expect(
        catalog.kidoLines.variants(KidoEvent.praise, ContentLanguage.hi),
        hasLength(greaterThanOrEqualTo(5)),
      );
    });

    test('caches the catalog', () async {
      final repo = ContentRepository(bundle: rootBundle, validate: false);
      expect(identical(await repo.load(), await repo.load()), isTrue);
    });

    test('filters sections and items by level', () async {
      final catalog = await ContentRepository(
        bundle: rootBundle,
        validate: false,
      ).load();
      // Vegetables, family and days start in LKG; months and opposites
      // in UKG. Body parts are for everyone.
      final nursery = catalog.sectionsFor(Level.nursery).map((s) => s.id);
      expect(nursery, contains(SectionId.body));
      for (final later in [
        SectionId.vegetables,
        SectionId.family,
        SectionId.days,
        SectionId.months,
        SectionId.opposites,
      ]) {
        expect(nursery, isNot(contains(later)));
      }
      // Babies (1–3): first words, sounds, colours, body, vehicles; no
      // letters yet, and numbers only to five.
      expect(catalog.sectionsFor(Level.baby).map((s) => s.id), [
        SectionId.numbers,
        SectionId.animals,
        SectionId.birds,
        SectionId.fruits,
        SectionId.colours,
        SectionId.shapes,
        SectionId.vehicles,
        SectionId.body,
      ]);
      expect(
        catalog.itemsFor(SectionId.numbers, level: Level.baby),
        hasLength(5),
      );
      expect(
        catalog.itemsFor(SectionId.shapes, level: Level.baby).map((i) => i.id),
        ['circle', 'square', 'triangle', 'star'],
      );
      final lkg = catalog.sectionsFor(Level.lkg).map((s) => s.id);
      expect(lkg, containsAll([SectionId.family, SectionId.days]));
      expect(lkg, isNot(contains(SectionId.months)));
      expect(
        catalog.sectionsFor(Level.ukg),
        hasLength(SectionId.values.length),
      );
      expect(
        catalog.itemsFor(SectionId.numbers, level: Level.nursery),
        hasLength(20),
      );
      expect(
        catalog.itemsFor(SectionId.animals, level: Level.lkg),
        hasLength(15),
      );
    });
  });

  test('invalid content throws a ContentValidationException', () async {
    const brokenAbc = '''
[{"id": "a_apple", "section": "abc", "levels": ["nursery"], "letter": "A",
  "number": null, "word_en": "Apple", "word_hi": "",
  "image": "assets/images/abc/missing.webp",
  "voice_en": "assets/audio/en/a_apple.m4a",
  "voice_hi": "assets/audio/hi/a_apple.m4a",
  "sound": null, "rive_reaction": null}]''';
    final repo = ContentRepository(
      bundle: _PatchedBundle({'assets/content/items_abc.json': brokenAbc}),
      validate: true,
    );
    await expectLater(
      repo.load(),
      throwsA(
        isA<ContentValidationException>().having(
          (e) => e.errors,
          'errors',
          containsAll([
            'item "a_apple": "word_hi" is empty',
            'item "a_apple": "image" file not found: '
                'assets/images/abc/missing.webp',
          ]),
        ),
      ),
    );
  });

  test('malformed JSON names the file', () async {
    final repo = ContentRepository(
      bundle: _PatchedBundle({'assets/content/items_birds.json': '[{'}),
      validate: false,
    );
    await expectLater(
      repo.load(),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('items_birds.json'),
        ),
      ),
    );
  });
}
