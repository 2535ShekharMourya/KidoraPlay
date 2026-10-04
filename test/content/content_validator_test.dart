import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/kido_line.dart';
import 'package:kidoraplay/content/models/learning_item.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/models/section.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_validator.dart';
import 'package:kidoraplay/content/spelling.dart';

LearningItem item({
  String id = 'cow',
  SectionId section = SectionId.animals,
  String wordEn = 'Cow',
  String wordHi = 'गाय',
  List<Level> levels = const [Level.nursery],
  String? letter,
  int? number,
  String? sound = 'default',
  String? image,
}) => LearningItem(
  id: id,
  section: section,
  levels: levels,
  wordEn: wordEn,
  wordHi: wordHi,
  letter: letter,
  number: number,
  image: image ?? 'assets/images/${section.name}/$id.webp',
  voiceEn: 'assets/audio/en/$id.m4a',
  voiceHi: 'assets/audio/hi/$id.m4a',
  sound: sound == 'default' ? 'assets/audio/${section.name}/$id.m4a' : sound,
);

Section section(SectionId id) => Section(
  id: id,
  titleEn: id.name,
  titleHi: id.name,
  levels: const [Level.nursery],
  itemsFile: 'assets/content/items_${id.name}.json',
  image: 'assets/images/sections/${id.name}.webp',
  voiceEn: 'assets/audio/en/sections/${id.name}.m4a',
  voiceHi: 'assets/audio/hi/sections/${id.name}.m4a',
);

KidoLines completeLines() => KidoLines({
  for (final e in KidoEvent.all)
    e: {
      for (final lang in ContentLanguage.values)
        lang: [
          KidoLine(
            text: '$e {item}',
            audio: ['assets/audio/${lang.name}/kido/$e.m4a', '{item}'],
          ),
        ],
    },
});

ContentCatalog catalog(List<LearningItem> items, {KidoLines? lines}) {
  final bySection = <SectionId, List<LearningItem>>{};
  for (final i in items) {
    (bySection[i.section] ??= []).add(i);
  }
  return ContentCatalog(
    sections: [for (final id in bySection.keys) section(id)],
    items: bySection,
    kidoLines: lines ?? completeLines(),
  );
}

/// Every asset the catalog references, so it validates cleanly.
Set<String> assetsOf(ContentCatalog c) => {
  for (final s in c.sections) ...[s.image, s.voiceEn, s.voiceHi],
  for (final i in c.allItems) ...[
    i.image,
    i.voiceEn,
    i.voiceHi,
    if (i.sound != null) i.sound!,
    for (final t in i.spelling)
      if (t.audioAsset != null) t.audioAsset!,
  ],
  for (final e in KidoEvent.all)
    for (final lang in ContentLanguage.values)
      for (final l in c.kidoLines.variants(e, lang)) ...l.audioFiles,
};

List<String> validate(ContentCatalog c, {Set<String>? assets}) =>
    validateContent(c, assets: assets ?? assetsOf(c));

void main() {
  test('valid content has no errors', () {
    final c = catalog([
      item(),
      item(
        id: 'twenty_one',
        section: SectionId.numbers,
        wordEn: 'Twenty-one',
        number: 21,
        sound: null,
      ),
      item(
        id: 'i_ice_cream',
        section: SectionId.abc,
        wordEn: 'Ice Cream',
        letter: 'I',
        sound: null,
      ),
    ]);
    expect(validate(c), isEmpty);
  });

  test('duplicate ids are reported', () {
    final c = catalog([item(), item()]);
    expect(validate(c), contains('item "cow": duplicate id'));
  });

  test('duplicate ids across sections are reported', () {
    final c = catalog([
      item(id: 'crow'),
      item(id: 'crow', section: SectionId.birds, wordEn: 'Crow'),
    ]);
    expect(validate(c), contains('item "crow": duplicate id'));
  });

  test('missing asset files are reported with the path', () {
    final c = catalog([item()]);
    final assets = assetsOf(c)..remove('assets/audio/hi/cow.m4a');
    expect(
      validate(c, assets: assets),
      contains(
        'item "cow": "voice_hi" file not found: assets/audio/hi/cow.m4a',
      ),
    );
  });

  test('missing letter audio is reported', () {
    final c = catalog([item()]);
    final assets = assetsOf(c)..remove(letterAudioAsset('W'));
    expect(validate(c, assets: assets).single, contains('letter W audio'));
  });

  test('empty fields are reported', () {
    final c = catalog([item(wordEn: ' ', wordHi: '', levels: const [])]);
    final errors = validate(c);
    expect(errors, contains('item "cow": "word_en" is empty'));
    expect(errors, contains('item "cow": "word_hi" is empty'));
    expect(errors, contains('item "cow": "levels" is empty'));
  });

  test('ids must be lowercase snake_case', () {
    final c = catalog([item(id: 'Big-Cow')]);
    expect(
      validate(c),
      contains('item "Big-Cow": id must be lowercase snake_case'),
    );
  });

  test('asset file names must match the id', () {
    final c = catalog([item(image: 'assets/images/animals/cow2.webp')]);
    final errors = validate(c, assets: assetsOf(c));
    expect(errors.single, contains('"image" file name must match the id'));
  });

  test('images must be webp', () {
    final c = catalog([item(image: 'assets/images/animals/cow.png')]);
    expect(validate(c), contains('item "cow": "image" must be a .webp file'));
  });

  test('word_en must be spellable', () {
    final c = catalog([item(wordEn: 'Cow!')]);
    expect(validate(c).single, contains('may only contain letters'));
  });

  test('number word must match the number', () {
    final c = catalog([
      item(
        id: 'twenty_one',
        section: SectionId.numbers,
        wordEn: 'Twenty One',
        number: 21,
        sound: null,
      ),
    ]);
    expect(
      validate(c),
      contains('item "twenty_one": "word_en" should be "Twenty-one" for 21'),
    );
  });

  test('numbers need a number 1–100', () {
    final c = catalog([
      item(id: 'zero', section: SectionId.numbers, wordEn: 'Zero', sound: null),
    ]);
    expect(validate(c), contains('item "zero": "number" must be 1–100'));
  });

  test('abc items need a capital letter matching the word', () {
    final c = catalog([
      item(id: 'b_apple', section: SectionId.abc, wordEn: 'Apple', letter: 'B'),
      item(id: 'x_box', section: SectionId.abc, wordEn: 'Box', letter: 'x'),
    ]);
    final errors = validate(c);
    expect(errors, contains('item "b_apple": "word_en" must start with "B"'));
    expect(
      errors,
      contains('item "x_box": "letter" must be one capital letter A–Z'),
    );
  });

  test('animals and birds need a sound', () {
    final c = catalog([item(sound: null)]);
    expect(validate(c), contains('item "cow": "sound" is required'));
  });

  test('item listed in the wrong section file is reported', () {
    final c = ContentCatalog(
      sections: [section(SectionId.birds)],
      items: {
        SectionId.birds: [item()],
      },
      kidoLines: completeLines(),
    );
    expect(validate(c).first, contains('listed in the "birds" items file'));
  });

  test('missing kido events and languages are reported', () {
    final c = catalog([item()], lines: const KidoLines({}));
    final errors = validate(c);
    expect(errors, contains('kido line "praise" (en): missing'));
    expect(errors, contains('kido line "goodbye" (hi): missing'));
  });

  test('kido audio placeholder must appear in the text', () {
    final lines = KidoLines({
      for (final e in KidoEvent.all)
        e: {
          for (final lang in ContentLanguage.values)
            lang: [
              const KidoLine(text: 'Hi', audio: ['{item}']),
            ],
        },
    });
    final c = catalog([item()], lines: lines);
    expect(
      validate(c),
      contains('kido line "praise" (en): audio placeholder {item} not in text'),
    );
  });
}
