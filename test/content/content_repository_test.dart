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
      for (final id in SectionId.values) {
        expect(catalog.itemsFor(id), hasLength(10), reason: id.name);
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
      final catalog =
          await ContentRepository(bundle: rootBundle, validate: false).load();
      expect(catalog.sectionsFor(Level.nursery), hasLength(4));
      expect(
        catalog.itemsFor(SectionId.animals, level: Level.lkg),
        hasLength(10),
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
