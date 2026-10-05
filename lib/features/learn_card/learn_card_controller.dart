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
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_tokens.dart';
import '../kido/hint_timer.dart';
import '../kido/kido_memory.dart';
import '../kido/kido_voice.dart';
import '../progress/progress_controller.dart';
import '../rewards/balloon_party.dart';
import '../section_grid/section_items.dart';

/// Where the learn card is.
enum LessonPhase {
  /// Nothing yet.
  idle,

  /// Kido names it ("A for Apple!"). Short: the child acts next.
  iDo,

  /// The child taps the picture to discover more, earning a star each time.
  youDo,

  /// All stars earned (celebrated); taps keep discovering, for fun.
  done,
}

/// What one tap on the picture reveals, in order of excitement.
enum Discovery {
  /// The real sound (animals, birds, vehicles), with the picture reacting.
  sound,

  /// "Let's count!" 1, 2, 3 … (numbers up to ten).
  count,

  /// A one-line fun fact (or the little chat on Hindi cards).
  fact,

  /// The letters light up one by one (the letter itself on Hindi cards).
  spell,

  /// "Say it with me… Apple!" with a quiet pause for the child, then "Yay!".
  say,
}

@immutable
class LearnCardState {
  const LearnCardState({
    this.phase = LessonPhase.idle,
    this.highlighted,
    this.revealed = 0,
    this.reacting = false,
    this.hint = HintLevel.none,
    this.celebrations = 0,
    this.counted = 0,
    this.cheers = 0,
    this.stickers = 0,
    this.completions = 0,
    this.stars = 0,
    this.starGoal = 0,
    this.busy = false,
    this.discovery,
    this.parties = 0,
  });

  final LessonPhase phase;

  /// Spelling tile currently lit up (being spoken), if any.
  final int? highlighted;

  /// How many spelling tiles are visible.
  final int revealed;

  /// The picture is reacting to its sound (animals, birds).
  final bool reacting;

  /// Idle hint level (the picture is the target).
  final HintLevel hint;

  /// Increments each time the child completes the card (all stars).
  final int celebrations;

  /// Number cards: how far Kido has counted (0 = not counting).
  final int counted;

  /// Increments on small cheers (after "say it with me").
  final int cheers;

  /// Increments when the child earns a new sticker for this item.
  final int stickers;

  /// Increments when this item completes its set (row or section).
  final int completions;

  /// Stars earned on this card (one per discovery tap) out of [starGoal].
  final int stars;
  final int starGoal;

  /// A discovery (or the name) is playing; taps just bounce meanwhile.
  final bool busy;

  /// The discovery playing now, if any.
  final Discovery? discovery;

  /// Increments when the child earns a balloon party.
  final int parties;

  bool get playing => busy;

  LearnCardState copyWith({
    LessonPhase? phase,
    int? highlighted,
    bool clearHighlight = false,
    int? revealed,
    bool? reacting,
    HintLevel? hint,
    int? celebrations,
    int? counted,
    int? cheers,
    int? stickers,
    int? completions,
    int? stars,
    int? starGoal,
    bool? busy,
    Discovery? discovery,
    bool clearDiscovery = false,
    int? parties,
  }) => LearnCardState(
    phase: phase ?? this.phase,
    highlighted: clearHighlight ? null : highlighted ?? this.highlighted,
    revealed: revealed ?? this.revealed,
    reacting: reacting ?? this.reacting,
    hint: hint ?? this.hint,
    celebrations: celebrations ?? this.celebrations,
    counted: counted ?? this.counted,
    cheers: cheers ?? this.cheers,
    stickers: stickers ?? this.stickers,
    completions: completions ?? this.completions,
    stars: stars ?? this.stars,
    starGoal: starGoal ?? this.starGoal,
    busy: busy ?? this.busy,
    discovery: clearDiscovery ? null : discovery ?? this.discovery,
    parties: parties ?? this.parties,
  );
}

/// Runs one learn card the way toddlers engage best: the child sets the
/// pace and every tap pays off at once.
///
/// 1. Kido names it ("A for Apple!") — about two seconds.
/// 2. Each tap on the picture discovers something new — the sound, a count,
///    a fun fact, the spelling, "say it with me" — and earns a star.
/// 3. All stars: sticker, celebration, and "Let's see the next one!".
///
/// Taps never restart or cut off what's playing; they bounce and pop.
/// No "wrong" answers. Idle hints (look → point + "Tap the apple!" →
/// glow) bring a quiet child back. With sound off or a missing clip, every
/// step still runs silently on a timer.
class LearnCardController extends Notifier<LearnCardState> {
  LearnCardController(this.itemId);

  final String itemId;
  int _run = 0;

  /// The set this card belongs to, for stickers and set completion.
  ItemScope? _scope;
  bool _disposed = false;
  List<Discovery> _steps = const [];
  int _nextStep = 0;

  /// Most stars a card asks for: short enough to finish, long enough to
  /// see the best parts.
  static const maxStars = 3;

  late final HintTimer _hints = HintTimer(
    onLevel: _onHint,
    lookAfter: AppDurations.discoverLook,
    pointAfter: AppDurations.discoverPoint,
    glowAfter: AppDurations.discoverGlow,
  );

  LearningItem? get _item =>
      ref.read(contentCatalogProvider).value?.itemById(itemId);
  AudioService get _audio => ref.read(audioServiceProvider);

  /// Hindi letter cards are taught in Hindi whatever the app language.
  bool get _hindiCard => _item?.section == SectionId.hindi;

  List<ContentLanguage> get _languages => _hindiCard
      ? const [ContentLanguage.hi]
      : ref.read(settingsProvider).language.languages;

  List<ContentLanguage> get _talkLanguages => _hindiCard
      ? const [ContentLanguage.hi]
      : ref.read(settingsProvider).language.talkLanguages;

  @override
  LearnCardState build() {
    final audio = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _disposed = true;
      _run++;
      _hints.stop();
      unawaited(audio.stopVoice(owner: this));
    });
    return const LearnCardState();
  }

  bool _alive(int run) => !_disposed && ref.mounted && run == _run;

  /// Quiets the card while another screen (tracing) is on top of it.
  void pause() {
    _run++;
    _hints.stop();
    state = state.copyWith(busy: false, reacting: false, clearDiscovery: true);
    unawaited(ref.read(audioServiceProvider).stopVoice(owner: this));
  }

  /// Tells the card which set (section or numbers row) it is shown in.
  void attach(ItemScope scope) => _scope = scope;

  /// Opens the card.
  Future<void> start() => playLesson();

  /// The things this item can reveal, in tap order.
  List<Discovery> discoveriesFor(LearningItem item) {
    final n = item.number;
    return [
      if (item.sound != null) Discovery.sound,
      if (n != null && n <= AppDurations.countAlongMax) Discovery.count,
      if (_talkLanguages.any((l) => item.factVoice(l) != null)) Discovery.fact,
      if (item.section.hasSpelling || item.letterVoice != null) Discovery.spell,
      Discovery.say,
    ];
  }

  /// Names the item, then hands over to the child.
  Future<void> playLesson() async {
    final item = _item;
    if (item == null) return;
    final run = ++_run;
    _hints.stop();
    _steps = discoveriesFor(item);
    _nextStep = 0;
    state = state.copyWith(
      phase: LessonPhase.iDo,
      clearHighlight: true,
      revealed: item.spelling.length,
      hint: HintLevel.none,
      counted: 0,
      stars: 0,
      starGoal: math.min(maxStars, _steps.length),
      busy: true,
      clearDiscovery: true,
    );

    await _sayName(item, run);
    if (!_alive(run)) return;
    // Until the child has tapped a picture once: "Tap the picture, and see
    // what happens!". Never again after that (no nagging).
    if (!ref.read(kidoMemoryProvider).discovered) {
      await _kidoSay(KidoEvent.tapToPlay, run);
      if (!_alive(run)) return;
    }
    state = state.copyWith(phase: LessonPhase.youDo, busy: false);
    _hints.start();
  }

  /// Child tapped the picture: discover the next thing (and earn a star).
  Future<void> tapPicture() async {
    final item = _item;
    if (item == null || state.phase == LessonPhase.idle) return;

    // Something is playing: a happy bounce and pop, never a restart.
    if (state.busy && state.phase != LessonPhase.iDo) {
      _audio.playSfx(Sfx.pop);
      return;
    }

    // Tapping during the name means "I'm ready!": go straight on.
    final run = ++_run;
    _hints.stop();
    unawaited(ref.read(kidoMemoryProvider).markDiscovered());
    if (_steps.isEmpty) _steps = discoveriesFor(item);
    final step = _steps[_nextStep % _steps.length];
    _nextStep++;
    final earning =
        state.phase != LessonPhase.done && state.stars < state.starGoal;
    if (earning) _audio.playSfx(Sfx.sparkle);
    state = state.copyWith(
      phase: state.phase == LessonPhase.done
          ? LessonPhase.done
          : LessonPhase.youDo,
      busy: true,
      hint: HintLevel.none,
      stars: earning ? state.stars + 1 : state.stars,
      discovery: step,
      clearHighlight: true,
      reacting: false,
      counted: 0,
    );

    try {
      await _discover(step, item, run);
    } finally {
      if (_alive(run)) {
        state = state.copyWith(
          busy: false,
          reacting: false,
          clearHighlight: true,
          clearDiscovery: true,
          counted: 0,
        );
      }
    }
    if (!_alive(run)) return;

    if (earning && state.stars >= state.starGoal) {
      await _complete(item, run);
    } else if (state.phase != LessonPhase.done) {
      _hints.start();
    }
  }

  /// Child tapped a letter tile: say that letter (stops anything playing).
  Future<void> tapLetter(int index) async {
    final item = _item;
    if (item == null) return;
    final audio = item.spelling[index].audioAsset;
    if (audio == null) return;

    final run = ++_run;
    _hints.stop();
    state = state.copyWith(
      phase: state.phase == LessonPhase.done
          ? LessonPhase.done
          : LessonPhase.youDo,
      highlighted: index,
      revealed: item.spelling.length,
      reacting: false,
      counted: 0,
      busy: false,
      clearDiscovery: true,
    );
    await _speak([audio], run);
    if (!_alive(run)) return;
    state = state.copyWith(clearHighlight: true);
    if (state.phase != LessonPhase.done) _hints.start();
  }

  /// Child tapped the big Hindi letter: "अ… अनार!".
  Future<void> tapBigLetter() async {
    final item = _item;
    if (item == null || item.letterVoice == null) return;
    final run = ++_run;
    _hints.stop();
    state = state.copyWith(
      phase: state.phase == LessonPhase.done
          ? LessonPhase.done
          : LessonPhase.youDo,
      busy: false,
      reacting: false,
      clearDiscovery: true,
    );
    await _speak([item.letterVoice!, item.voiceHi], run);
    if (_alive(run) && state.phase != LessonPhase.done) _hints.start();
  }

  /// Any tap anywhere on the screen: hints go away and the clock restarts.
  void userTapped() => _hints.reset();

  Future<void> _sayName(LearningItem item, int run) async {
    if (item.section == SectionId.hindi && item.voiceIntroHi != null) {
      // "अ से अनार!" in one breath.
      await _speak([item.voiceIntroHi!], run);
    } else if (item.section == SectionId.hindi && item.letterVoice != null) {
      await _kidoSay(
        KidoEvent.letterFor,
        run,
        languages: const [ContentLanguage.hi],
        item: item,
        letterAudio: item.letterVoice,
      );
    } else if (item.section == SectionId.abc && item.voiceIntroEn != null) {
      // "A for Apple!" in one breath, then the Hindi word when bilingual.
      await _speak([
        item.voiceIntroEn!,
        if (_languages.contains(ContentLanguage.hi)) item.voiceHi,
      ], run);
    } else if (item.section == SectionId.abc && item.letter != null) {
      await _kidoSay(
        KidoEvent.letterFor,
        run,
        languages: const [ContentLanguage.en],
        item: item,
        letterAudio: item.spelling.first.audioAsset,
      );
      if (!_alive(run)) return;
      if (_languages.contains(ContentLanguage.hi)) {
        await _speak([item.voiceHi], run);
      }
    } else {
      await _speak(_words(item), run);
    }
  }

  Future<void> _discover(Discovery step, LearningItem item, int run) async {
    switch (step) {
      case Discovery.sound:
        state = state.copyWith(reacting: true);
        await _speak([item.sound!], run);
        if (!_alive(run)) return;
        state = state.copyWith(reacting: false);
        // "Lion!" again, so the sound and the name go together.
        await _speak([_words(item).first], run);

      case Discovery.count:
        await _countTo(item.number!, run);
        if (!_alive(run)) return;
        await _speak(_words(item), run);

      case Discovery.fact:
        await _speak([for (final l in _talkLanguages) ?item.factVoice(l)], run);

      case Discovery.spell:
        if (!item.section.hasSpelling) {
          // Hindi: the letter, then the word ("अ… अनार!").
          await _speak([?item.letterVoice, item.voiceHi], run);
          return;
        }
        final tiles = item.spelling;
        final voiced = _voicedIndexes(item);
        await _speak(
          [for (final i in voiced) tiles[i].audioAsset!],
          run,
          onSegment: (k) {
            if (_alive(run)) state = state.copyWith(highlighted: voiced[k]);
          },
        );
        if (!_alive(run)) return;
        state = state.copyWith(clearHighlight: true);
        await _speak([_words(item).first], run);

      case Discovery.say:
        await _kidoSay(KidoEvent.sayWithMe, run);
        if (!_alive(run)) return;
        await _speak(_words(item), run);
        if (!_alive(run)) return;
        await Future<void>.delayed(AppDurations.echoPause);
        if (!_alive(run)) return;
        state = state.copyWith(cheers: state.cheers + 1);
        await _kidoSay(KidoEvent.yay, run);
    }
  }

  /// All stars: sticker, celebration, then on to the next one.
  Future<void> _complete(LearningItem item, int run) async {
    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(
      phase: LessonPhase.done,
      hint: HintLevel.none,
      celebrations: state.celebrations + 1,
    );

    final scope = _scope ?? (section: item.section, row: null);
    final result = await ref
        .read(progressProvider.notifier)
        .markLearned(item, scope);
    if (!_alive(run)) return;
    state = state.copyWith(
      stickers: state.stickers + (result.newSticker ? 1 : 0),
    );

    await _kidoSay(KidoEvent.praise, run);
    if (!_alive(run)) return;

    if (result.completedScope) {
      // Finished the whole set: big celebration.
      state = state.copyWith(completions: state.completions + 1);
      _audio.playSfx(Sfx.sparkle);
      final catalog = ref.read(contentCatalogProvider).value;
      await _kidoSay(
        KidoEvent.sectionDone,
        run,
        n: ref.read(scopeItemsProvider(scope)).length,
        section: catalog?.section(scope.section),
      );
      return;
    }
    // Every few cards: a balloon party (the screen shows it and calls
    // [partyOver] when it ends).
    if (ref.read(sessionRewardsProvider).cardCompleted()) {
      state = state.copyWith(parties: state.parties + 1);
      await _kidoSay(KidoEvent.balloonParty, run);
      return;
    }
    await _sayNextOne(item, scope, run);
  }

  /// The balloon party ended: on to the next card.
  Future<void> partyOver() async {
    final item = _item;
    if (item == null) return;
    final run = ++_run;
    await _sayNextOne(item, _scope ?? (section: item.section, row: null), run);
  }

  Future<void> _sayNextOne(LearningItem item, ItemScope scope, int run) async {
    final items = ref.read(scopeItemsProvider(scope));
    final isLast = items.isNotEmpty && items.last.id == item.id;
    if (!isLast) await _kidoSay(KidoEvent.nextOne, run);
  }

  void _onHint(HintLevel level) {
    if (_disposed) return;
    state = state.copyWith(hint: level);
    if (level != HintLevel.point) return;
    final item = _item;
    if (item == null) return;
    // "Here it is! Tap the apple!"
    unawaited(_kidoSay(KidoEvent.hintTap, _run, item: item));
  }

  List<String> _words(LearningItem item) => [
    for (final l in _languages) item.voice(l),
  ];

  static List<int> _voicedIndexes(LearningItem item) => [
    for (final (i, t) in item.spelling.indexed)
      if (t.isVoiced) i,
  ];

  /// "Let's count!" then 1, 2, 3 … [n] in the first selected language, with
  /// the count shown on screen.
  Future<void> _countTo(int n, int run) async {
    await _kidoSay(KidoEvent.letsCount, run);
    if (!_alive(run)) return;
    final numbers =
        ref.read(contentCatalogProvider).value?.itemsFor(SectionId.numbers) ??
        const <LearningItem>[];
    final lang = _languages.first;
    final clips = [
      for (var k = 1; k <= n; k++)
        ?numbers.where((i) => i.number == k).firstOrNull?.voice(lang),
    ];
    if (clips.length != n) return;
    await _speak(
      clips,
      run,
      onSegment: (k) {
        if (_alive(run)) state = state.copyWith(counted: k + 1);
      },
    );
  }

  /// Plays [assets]; if nothing could be heard (muted or missing audio),
  /// steps through the segments silently so the visuals keep their rhythm.
  Future<void> _speak(
    List<String> assets,
    int run, {
    void Function(int index)? onSegment,
  }) async {
    if (assets.isEmpty || !_alive(run)) return;
    final ok = await _audio.playVoiceSequence(
      assets,
      onSegment: onSegment,
      debounce: false,
      owner: this,
    );
    if (ok || !_alive(run)) return;
    for (var i = 0; i < assets.length; i++) {
      if (!_alive(run)) return;
      onSegment?.call(i);
      await Future<void>.delayed(AppDurations.silentSegment);
    }
  }

  Future<void> _kidoSay(
    String event,
    int run, {
    List<ContentLanguage>? languages,
    LearningItem? item,
    String? itemAudio,
    String? letterAudio,
    int? n,
    Section? section,
  }) async {
    if (!_alive(run)) return;
    final ok = await ref
        .read(kidoVoiceProvider)
        .say(
          event,
          languages: languages ?? (_hindiCard ? _talkLanguages : null),
          item: item,
          itemAudio: itemAudio,
          letterAudio: letterAudio,
          n: n,
          section: section,
          owner: this,
        );
    if (!ok && _alive(run)) {
      await Future<void>.delayed(AppDurations.silentSegment * 2);
    }
  }
}

final learnCardControllerProvider = NotifierProvider.autoDispose
    .family<LearnCardController, LearnCardState, String>(
      LearnCardController.new,
    );
