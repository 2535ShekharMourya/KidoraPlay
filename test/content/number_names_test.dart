import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/number_names.dart';

void main() {
  group('numberNameEn', () {
    const expected = {
      1: 'One',
      2: 'Two',
      10: 'Ten',
      11: 'Eleven',
      13: 'Thirteen',
      15: 'Fifteen',
      19: 'Nineteen',
      20: 'Twenty',
      21: 'Twenty-one',
      30: 'Thirty',
      40: 'Forty',
      45: 'Forty-five',
      58: 'Fifty-eight',
      77: 'Seventy-seven',
      80: 'Eighty',
      99: 'Ninety-nine',
      100: 'One Hundred',
    };

    expected.forEach((n, name) {
      test('$n → $name', () => expect(numberNameEn(n), name));
    });

    test('all 1–100 are unique, non-empty and spellable', () {
      final names = [for (var n = 1; n <= 100; n++) numberNameEn(n)];
      expect(names.toSet(), hasLength(100));
      final spellable = RegExp(r'^[A-Za-z]+([ -][A-Za-z]+)*$');
      for (final name in names) {
        expect(spellable.hasMatch(name), isTrue, reason: name);
      }
    });

    test('rejects numbers outside 1–100', () {
      expect(() => numberNameEn(0), throwsRangeError);
      expect(() => numberNameEn(101), throwsRangeError);
    });
  });

  group('placeValue', () {
    test('splits into tens and ones', () {
      expect(placeValue(21), (tens: 2, ones: 1));
      expect(placeValue(7), (tens: 0, ones: 7));
      expect(placeValue(90), (tens: 9, ones: 0));
      expect(placeValue(100), (tens: 10, ones: 0));
    });
  });
}
