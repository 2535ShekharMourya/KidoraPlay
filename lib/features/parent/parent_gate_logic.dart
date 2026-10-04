import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// A task a toddler can't do but a parent can in seconds. Randomised so it
/// can't be learned by watching.
sealed class GateChallenge {
  const GateChallenge();

  /// Picks a random challenge.
  factory GateChallenge.random(math.Random random) => random.nextBool()
      ? const HoldChallenge()
      : NumberChallenge.random(random);
}

/// "Press and hold the button for 3 seconds."
@immutable
class HoldChallenge extends GateChallenge {
  const HoldChallenge();

  static const holdFor = Duration(seconds: 3);
}

/// "Tap the number seven": the number is written as a word, the options
/// are digits, so it needs reading.
@immutable
class NumberChallenge extends GateChallenge {
  const NumberChallenge({required this.answer, required this.options});

  factory NumberChallenge.random(math.Random random) {
    final answer = 1 + random.nextInt(9);
    final options = <int>{answer};
    while (options.length < optionCount) {
      options.add(1 + random.nextInt(9));
    }
    return NumberChallenge(
      answer: answer,
      options: List.unmodifiable(options.toList()..shuffle(random)),
    );
  }

  static const optionCount = 4;

  /// 1–9.
  final int answer;

  /// Digits shown as buttons, in random order; includes [answer].
  final List<int> options;

  bool isCorrect(int choice) => choice == answer;
}
