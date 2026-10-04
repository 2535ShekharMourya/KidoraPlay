import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/spelling.dart';

List<String> chars(String word) => spellingOf(word).map((t) => t.char).toList();

void main() {
  group('spellingOf', () {
    test('uppercases each letter', () {
      expect(chars('Apple'), ['A', 'P', 'P', 'L', 'E']);
    });

    test('every letter is voiced with its shared letter recording', () {
      final tiles = spellingOf('Cat');
      expect(tiles.every((t) => t.isVoiced), isTrue);
      expect(tiles.map((t) => t.audioAsset), [
        'assets/audio/letters/c.m4a',
        'assets/audio/letters/a.m4a',
        'assets/audio/letters/t.m4a',
      ]);
    });

    test('hyphens are shown but silent', () {
      final tiles = spellingOf('Twenty-one');
      expect(chars('Twenty-one').join(), 'TWENTY-ONE');
      final hyphen = tiles[6];
      expect(hyphen.char, '-');
      expect(hyphen.isVoiced, isFalse);
      expect(hyphen.audioAsset, isNull);
    });

    test('spaces are shown but silent, repeated spaces collapse', () {
      expect(chars('  Ice   Cream '), [
        'I',
        'C',
        'E',
        ' ',
        'C',
        'R',
        'E',
        'A',
        'M',
      ]);
      expect(spellingOf('Ice Cream')[3].isVoiced, isFalse);
    });

    test('empty word gives no tiles', () {
      expect(spellingOf('   '), isEmpty);
    });

    test('result is unmodifiable', () {
      expect(
        () => spellingOf('Hen').add(const SpellingTile('X')),
        throwsUnsupportedError,
      );
    });
  });
}
