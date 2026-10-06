import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../content/models/learning_item.dart';
import '../../content/models/level.dart';
import '../../content/models/section.dart';
import '../../content/number_names.dart';
import '../../content/repository/content_catalog.dart';
import '../../content/spelling.dart';

/// The practice games. Each is a short quiz of [roundsPerGame] rounds.
enum GameKind {
  /// "Where is the cow?": tap the right picture.
  findIt(SectionId.animals),

  /// A real animal sound plays: tap who makes it.
  whoSays(SectionId.birds),

  /// "How many?": count the pictures, tap the number.
  countIt(SectionId.numbers),

  /// "Find the letter A!": tap the letter.
  letters(SectionId.abc);

  const GameKind(this.theme);

  /// Section whose colours and background the game uses.
  final SectionId theme;
}

const roundsPerGame = 5;

/// Rounds in one game: shorter for babies (1–3), who count to three.
int roundsFor(Level level) => level == Level.baby ? 3 : roundsPerGame;

/// Choices per round grow with the class: Nursery 2, LKG 3, UKG 4.
int choicesFor(Level level) => switch (level) {
  Level.baby || Level.nursery => 2,
  Level.lkg => 3,
  Level.ukg => 4,
};

/// Counting goes up to 5 in Nursery, 10 after that.
int countMaxFor(Level level) => switch (level) {
  Level.baby => 3,
  Level.nursery => 5,
  Level.lkg || Level.ukg => 10,
};

/// One tappable answer.
@immutable
class QuizChoice {
  const QuizChoice({
    required this.id,
    required this.label,
    this.item,
    this.text,
    this.clip,
  });

  final String id;

  /// For TalkBack.
  final String label;

  /// Picture choices (animals, birds).
  final LearningItem? item;

  /// Text choices (a letter or a numeral).
  final String? text;

  /// Clip that names a text choice (letter or number).
  final String? clip;

  @override
  bool operator ==(Object other) => other is QuizChoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class QuizRound {
  const QuizRound({
    required this.kind,
    required this.answer,
    required this.choices,
    this.subject,
    this.count,
  });

  final GameKind kind;
  final QuizChoice answer;

  /// Shuffled, includes [answer].
  final List<QuizChoice> choices;

  /// Count-it: the picture shown [count] times.
  final LearningItem? subject;
  final int? count;
}

/// Builds a game's rounds from the content for the selected class.
/// Answers don't repeat within a game; distractors are random.
List<QuizRound> buildQuiz(
  GameKind kind,
  ContentCatalog catalog,
  Level level,
  math.Random random, {
  int? rounds,
  int? maxChoices,
}) {
  // Fewer choices on screens too narrow for big cards.
  final roundCount = rounds ?? roundsFor(level);
  final choiceCount = math.max(
    2,
    math.min(choicesFor(level), maxChoices ?? choicesFor(level)),
  );

  QuizChoice pictureChoice(LearningItem i) =>
      QuizChoice(id: i.id, label: i.wordEn, item: i);

  List<QuizChoice> withDistractors(QuizChoice answer, List<QuizChoice> pool) {
    final others = [...pool.where((c) => c != answer)]..shuffle(random);
    return [answer, ...others.take(choiceCount - 1)]..shuffle(random);
  }

  switch (kind) {
    case GameKind.findIt || GameKind.whoSays:
      final items = [
        ...catalog.itemsFor(SectionId.animals, level: level),
        ...catalog.itemsFor(SectionId.birds, level: level),
        if (kind == GameKind.findIt) ...[
          ...catalog.itemsFor(SectionId.fruits, level: level),
          ...catalog.itemsFor(SectionId.vegetables, level: level),
          // "Where is the nose?"
          ...catalog.itemsFor(SectionId.body, level: level),
        ],
      ].where((i) => kind == GameKind.findIt || i.sound != null).toList();
      final pool = items.map(pictureChoice).toList();
      final answers = [...pool]..shuffle(random);
      return [
        for (final answer in answers.take(roundCount))
          QuizRound(
            kind: kind,
            answer: answer,
            choices: withDistractors(answer, pool),
          ),
      ];

    case GameKind.countIt:
      final max = countMaxFor(level);
      final numbers = {
        for (final i in catalog.itemsFor(SectionId.numbers))
          if (i.number != null && i.number! <= max) i.number!: i,
      };
      final pool = [
        for (var n = 1; n <= max; n++)
          QuizChoice(
            id: 'n$n',
            label: numberNameEn(n),
            text: '$n',
            clip: numbers[n]?.voiceEn,
          ),
      ];
      final subjects = [
        ...catalog.itemsFor(SectionId.fruits),
        ...catalog.itemsFor(SectionId.animals),
        ...catalog.itemsFor(SectionId.birds),
      ]..shuffle(random);
      final answers = [...pool]..shuffle(random);
      return [
        for (final (i, answer) in answers.take(roundCount).indexed)
          QuizRound(
            kind: kind,
            answer: answer,
            choices: withDistractors(answer, pool),
            subject: subjects[i % subjects.length],
            count: int.parse(answer.text!),
          ),
      ];

    case GameKind.letters:
      final pool = [
        // Letters aren't in the baby class; if the game is opened anyway,
        // use the Nursery letters rather than an empty game.
        for (final i in catalog.itemsFor(
          SectionId.abc,
          level: level == Level.baby ? Level.nursery : level,
        ))
          if (i.letter != null)
            QuizChoice(
              id: 'l${i.letter}',
              label: i.letter!,
              text: i.letter,
              clip: letterAudioAsset(i.letter!),
              item: i,
            ),
      ];
      final answers = [...pool]..shuffle(random);
      return [
        for (final answer in answers.take(roundCount))
          QuizRound(
            kind: kind,
            answer: answer,
            choices: withDistractors(answer, pool),
          ),
      ];
  }
}
