import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/kido_line.dart';
import 'package:kidoraplay/content/models/learning_item.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/models/section.dart';

Map<String, Object?> appleJson() => {
      'id': 'a_apple',
      'section': 'abc',
      'levels': ['nursery', 'lkg'],
      'letter': 'A',
      'number': null,
      'word_en': 'Apple',
      'word_hi': 'सेब',
      'image': 'assets/images/abc/a_apple.webp',
      'voice_en': 'assets/audio/en/a_apple.m4a',
      'voice_hi': 'assets/audio/hi/a_apple.m4a',
      'sound': null,
      'fact_en': 'An apple is red and yummy!',
      'fact_hi': 'सेब लाल और मीठा होता है!',
      'voice_fact_en': 'assets/audio/en/a_apple_fact.m4a',
      'voice_fact_hi': 'assets/audio/hi/a_apple_fact.m4a',
      'rive_reaction': null,
    };

void main() {
  group('LearningItem', () {
    test('parses JSON', () {
      final item = LearningItem.fromJson(appleJson());
      expect(item.id, 'a_apple');
      expect(item.section, SectionId.abc);
      expect(item.levels, [Level.nursery, Level.lkg]);
      expect(item.letter, 'A');
      expect(item.word(ContentLanguage.hi), 'सेब');
      expect(item.isForLevel(Level.ukg), isFalse);
      expect(item.spelling.map((t) => t.char).join(), 'APPLE');
    });

    test('round-trips through toJson', () {
      final json = appleJson();
      expect(LearningItem.fromJson(json).toJson(), json);
    });

    test('wrong field type gives a clear error naming file, item and field',
        () {
      final json = appleJson()..['word_en'] = 42;
      expect(
        () => LearningItem.fromJson(json, file: 'items_abc.json'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('items_abc.json'),
              contains('a_apple'),
              contains('word_en'),
            ),
          ),
        ),
      );
    });

    test('unknown level is rejected', () {
      final json = appleJson()..['levels'] = ['playgroup'];
      expect(() => LearningItem.fromJson(json), throwsFormatException);
    });
  });

  group('Section', () {
    test('round-trips through toJson', () {
      final json = {
        'id': 'birds',
        'title_en': 'Birds',
        'title_hi': 'पक्षी',
        'levels': ['nursery', 'lkg', 'ukg'],
        'items': 'assets/content/items_birds.json',
        'image': 'assets/images/sections/birds.webp',
        'voice_en': 'assets/audio/en/sections/birds.m4a',
        'voice_hi': 'assets/audio/hi/sections/birds.m4a',
      };
      final section = Section.fromJson(json);
      expect(section.id, SectionId.birds);
      expect(section.title(ContentLanguage.hi), 'पक्षी');
      expect(section.toJson(), json);
    });
  });

  group('KidoLines', () {
    test('parses events per language and finds audio files', () {
      final lines = KidoLines.fromJson({
        'hint_tap': {
          'en': [
            {
              'text': 'Tap the {item}!',
              'audio': ['assets/audio/en/kido/hint_tap.m4a', '{item}'],
            },
          ],
          'hi': [
            {
              'text': '{item} को छुओ!',
              'audio': ['{item}', 'assets/audio/hi/kido/hint_tap.m4a'],
            },
          ],
        },
      });
      final hi = lines.variants(KidoEvent.hintTap, ContentLanguage.hi).single;
      expect(hi.audio.first, '{item}');
      expect(hi.audioFiles, ['assets/audio/hi/kido/hint_tap.m4a']);
      expect(lines.variants('unknown', ContentLanguage.en), isEmpty);
    });
  });
}
