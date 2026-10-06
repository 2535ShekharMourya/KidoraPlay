import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../games/quiz_controller.dart' show quizRandomProvider;
import '../kido/kido_controller.dart';
import '../kido/kido_voice.dart';

/// Where on Kido a tap landed (fractions of his box; he faces right).
enum KidoSpot {
  head,
  body,
  trunk;

  /// Head (and big ear) around (0.55, 0.40); trunk at the right; the rest
  /// is his tummy.
  static KidoSpot at(Offset p) {
    if (p.dx > 0.78 && p.dy > 0.30) return KidoSpot.trunk;
    final head = (p - const Offset(0.58, 0.38)).distance;
    if (head < 0.24 || p.dy < 0.30) return KidoSpot.head;
    return KidoSpot.body;
  }
}

/// Hats Kido can wear (null = none).
enum KidoHat {
  crown('assets/images/room/crown.webp'),
  cap('assets/images/room/cap.webp'),
  topHat('assets/images/room/tophat.webp');

  const KidoHat(this.image);

  final String image;
}

@immutable
class KidoRoomState {
  const KidoRoomState({this.hat, this.food, this.feeds = 0, this.baths = 0});

  final KidoHat? hat;

  /// The fruit flying to Kido's mouth right now.
  final LearningItem? food;

  /// Increment on every feed / bath (drive the animations).
  final int feeds;
  final int baths;

  KidoRoomState copyWith({
    KidoHat? hat,
    bool noHat = false,
    LearningItem? food,
    int? feeds,
    int? baths,
  }) => KidoRoomState(
    hat: noHat ? null : hat ?? this.hat,
    food: food ?? this.food,
    feeds: feeds ?? this.feeds,
    baths: baths ?? this.baths,
  );
}

/// Kido's Room: pat, tickle and feed Kido, give him a bath, try on hats.
/// Pure play with words in it (fruit names); no microphone, and no needs
/// that make a child come back (Kido is never hungry or sad).
class KidoRoomController extends Notifier<KidoRoomState> {
  AudioService get _audio => ref.read(audioServiceProvider);
  KidoController get _kido => ref.read(kidoControllerProvider.notifier);

  @override
  KidoRoomState build() {
    final audio = _audio;
    ref.onDispose(() => unawaited(audio.stopVoice(owner: this)));
    return const KidoRoomState();
  }

  Future<void> hello() => _say(KidoEvent.roomHello);

  /// The child touched Kido at [spot].
  Future<void> touch(KidoSpot spot) async {
    ref.read(hapticsProvider).tap();
    switch (spot) {
      case KidoSpot.head:
        _kido.act(KidoAction.think);
        await _say(KidoEvent.roomPat);
      case KidoSpot.body:
        _kido.act(KidoAction.clap);
        await _say(KidoEvent.roomTickle);
      case KidoSpot.trunk:
        // A real elephant trumpet.
        _kido.act(KidoAction.trumpet);
        await _audio.playVoiceSequence(
          ['assets/audio/animals/elephant.m4a'],
          debounce: false,
          owner: this,
        );
    }
  }

  /// A fruit flies into Kido's mouth: "Yum yum! Banana!".
  Future<void> feed() async {
    final fruits =
        ref.read(contentCatalogProvider).value?.itemsFor(SectionId.fruits) ??
        const <LearningItem>[];
    if (fruits.isEmpty) return;
    final random = ref.read(quizRandomProvider);
    var fruit = fruits[random.nextInt(fruits.length)];
    if (fruit.id == state.food?.id && fruits.length > 1) {
      fruit = fruits[(fruits.indexOf(fruit) + 1) % fruits.length];
    }
    state = state.copyWith(food: fruit, feeds: state.feeds + 1);
    _audio.playSfx(Sfx.pop);
    _kido.act(KidoAction.clap);
    await _say(KidoEvent.roomYum, item: fruit);
  }

  /// Bubbles everywhere: "Splish splash!".
  Future<void> bath() async {
    state = state.copyWith(baths: state.baths + 1);
    _audio.playSfx(Sfx.sparkle);
    _kido.act(KidoAction.surprised);
    await _say(KidoEvent.roomBath);
  }

  /// Next hat (crown, cap, top hat, then none).
  Future<void> nextHat() async {
    const hats = KidoHat.values;
    final i = state.hat == null ? 0 : hats.indexOf(state.hat!) + 1;
    if (i >= hats.length) {
      state = state.copyWith(noHat: true);
      _audio.playSfx(Sfx.whoosh);
      return;
    }
    state = state.copyWith(hat: hats[i]);
    _audio.playSfx(Sfx.sparkle);
    _kido.act(KidoAction.wave);
    await _say(KidoEvent.roomHat);
  }

  Future<void> _say(String event, {LearningItem? item}) async {
    if (!ref.mounted) return;
    await ref.read(kidoVoiceProvider).say(event, item: item, owner: this);
  }
}

final kidoRoomControllerProvider =
    NotifierProvider.autoDispose<KidoRoomController, KidoRoomState>(
      KidoRoomController.new,
    );
