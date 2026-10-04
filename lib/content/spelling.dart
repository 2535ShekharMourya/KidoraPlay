import 'package:flutter/foundation.dart';

final _voicedLetter = RegExp('^[A-Z]\$');

/// Asset path of the shared recording for one letter (A–Z).
String letterAudioAsset(String letter) =>
    'assets/audio/letters/${letter.toLowerCase()}.m4a';

/// One tile in the spelling strip.
@immutable
class SpellingTile {
  const SpellingTile(this.char);

  final String char;

  /// Letters are spoken; hyphens and spaces are shown but silent.
  bool get isVoiced => _voicedLetter.hasMatch(char);

  String? get audioAsset => isVoiced ? letterAudioAsset(char) : null;

  @override
  bool operator ==(Object other) => other is SpellingTile && other.char == char;

  @override
  int get hashCode => char.hashCode;

  @override
  String toString() => 'SpellingTile($char)';
}

/// Builds the spelling tiles for [word]: uppercase, repeated whitespace
/// collapsed to a single (silent) space.
List<SpellingTile> spellingOf(String word) {
  final normalised = word.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  return List.unmodifiable(normalised.split('').map(SpellingTile.new));
}
