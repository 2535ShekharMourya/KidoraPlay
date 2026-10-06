import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/learning_item.dart';
import '../../content/models/level.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_tokens.dart';
import '../games/quiz_controller.dart' show quizRandomProvider;
import '../kido/kido_voice.dart';

@immutable
class MemoryCard {
  const MemoryCard(this.item, {this.faceUp = false, this.matched = false});

  final LearningItem item;
  final bool faceUp;
  final bool matched;

  MemoryCard copyWith({bool? faceUp, bool? matched}) => MemoryCard(
    item,
    faceUp: faceUp ?? this.faceUp,
    matched: matched ?? this.matched,
  );
}

@immutable
class MemoryState {
  const MemoryState({
    this.cards = const [],
    this.first,
    this.busy = false,
    this.matches = 0,
    this.games = 0,
  });

  final List<MemoryCard> cards;

  /// The card turned up first in this try, waiting for its partner.
  final int? first;

  /// Two different cards are showing before they turn back.
  final bool busy;

  /// Increments on every pair found (sparkle).
  final int matches;

  /// Increments when all pairs are found (celebration).
  final int games;

  bool get finished => cards.isNotEmpty && cards.every((c) => c.matched);

  MemoryState copyWith({
    List<MemoryCard>? cards,
    int? first,
    bool clearFirst = false,
    bool? busy,
    int? matches,
    int? games,
  }) => MemoryState(
    cards: cards ?? this.cards,
    first: clearFirst ? null : first ?? this.first,
    busy: busy ?? this.busy,
    matches: matches ?? this.matches,
    games: games ?? this.games,
  );
}

/// Pairs per class: few for the youngest.
int memoryPairsFor(Level level) => switch (level) {
  Level.nursery => 3,
  Level.lkg => 4,
  Level.ukg => 6,
};

/// Memory match: turn two cards; two the same stay up. Different ones
/// simply turn back (no "wrong"). Every card says its name.
class MemoryController extends Notifier<MemoryState> {
  Timer? _turnBack;
  int _maxCards = 12;

  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  MemoryState build() {
    final audio = _audio;
    ref.onDispose(() {
      _turnBack?.cancel();
      unawaited(audio.stopVoice(owner: this));
    });
    return const MemoryState();
  }

  /// Deals a new game with at most [maxCards] cards (what fits the screen).
  void start({int? maxCards}) {
    _maxCards = maxCards ?? _maxCards;
    _turnBack?.cancel();
    final catalog = ref.read(contentCatalogProvider).value;
    if (catalog == null) return;
    final random = ref.read(quizRandomProvider);
    final pool = [
      for (final s in [SectionId.animals, SectionId.fruits, SectionId.vehicles])
        ...catalog.itemsFor(s),
    ]..shuffle(random);
    final pairs = math.max(
      2,
      math.min(
        memoryPairsFor(ref.read(settingsProvider).level),
        _maxCards ~/ 2,
      ),
    );
    final cards = [
      for (final item in pool.take(pairs)) ...[
        MemoryCard(item),
        MemoryCard(item),
      ],
    ]..shuffle(random);
    state = MemoryState(cards: cards, games: state.games);
    unawaited(_say(KidoEvent.memoryStart));
  }

  void tap(int index) {
    if (index < 0 || index >= state.cards.length) return;
    final card = state.cards[index];
    if (state.busy || card.faceUp || card.matched) {
      _audio.playSfx(Sfx.pop);
      return;
    }
    ref.read(hapticsProvider).tap();
    _audio.playSfx(Sfx.tap);
    final cards = [...state.cards];
    cards[index] = card.copyWith(faceUp: true);
    unawaited(_name(card.item));

    final first = state.first;
    if (first == null) {
      state = state.copyWith(cards: cards, first: index);
      return;
    }
    if (cards[first].item.id == card.item.id) {
      // A pair! Both stay up.
      cards[first] = cards[first].copyWith(matched: true);
      cards[index] = cards[index].copyWith(matched: true);
      _audio.playSfx(Sfx.sparkle);
      state = state.copyWith(
        cards: cards,
        clearFirst: true,
        matches: state.matches + 1,
      );
      if (state.finished) unawaited(_finish());
      return;
    }
    // Not the same: look for a moment, then both turn back.
    state = state.copyWith(cards: cards, clearFirst: true, busy: true);
    _turnBack = Timer(AppDurations.memoryLook, () {
      if (!ref.mounted) return;
      state = state.copyWith(
        cards: [
          for (final c in state.cards)
            c.matched ? c : c.copyWith(faceUp: false),
        ],
        busy: false,
      );
    });
  }

  Future<void> _finish() async {
    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(games: state.games + 1);
    await Future<void>.delayed(AppDurations.quizNext);
    if (!ref.mounted) return;
    await _say(KidoEvent.gameDone);
  }

  Future<void> _name(LearningItem item) async {
    final lang = ref.read(settingsProvider).language.languages.first;
    await _audio.playVoiceSequence(
      [item.voice(lang)],
      debounce: false,
      owner: this,
    );
  }

  Future<void> _say(String event) async {
    if (!ref.mounted) return;
    await ref.read(kidoVoiceProvider).say(event, owner: this);
  }
}

final memoryControllerProvider =
    NotifierProvider.autoDispose<MemoryController, MemoryState>(
      MemoryController.new,
    );
