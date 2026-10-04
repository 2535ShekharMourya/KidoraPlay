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
import '../section_grid/section_items.dart';

/// Where the learn card is in "I do, we do, you do".
enum LessonPhase {
  /// Nothing yet.
  idle,

  /// Kido shows it: look, name, sound/count, fact, spelling, echo.
  iDo,

  /// "Now let's spell it together!": the child taps each glowing letter.
  weDo,

  /// "Where is the apple? Can you tap it?": the child taps the picture.
  youDo,

  /// Finished (celebrated); tapping the picture replays.
  done,
}

@immutable
class LearnCardState {
  const LearnCardState({
    this.phase = LessonPhase.idle,
    this.highlighted,
    this.revealed = 0,
    this.reacting = false,
    this.weDoTarget,
    this.hint = HintLevel.none,
    this.celebrations = 0,
    this.counted = 0,
    this.cheers = 0,
    this.stickers = 0,
    this.completions = 0,
  });

  final LessonPhase phase;

  /// Spelling tile currently lit up (being spoken), if any.
  final int? highlighted;

  /// How many spelling tiles are visible (they appear one by one).
  final int revealed;

  /// The picture is reacting to its sound (animals, birds).
  final bool reacting;

  /// During "we do": the letter tile the child should tap next.
  final int? weDoTarget;

  /// Idle hint level for the current target.
  final HintLevel hint;

  /// Increments each time the child completes the card.
  final int celebrations;

  /// Number cards: how far Kido has counted (0 = not counting).
  final int counted;

  /// Increments on small cheers (after "say it with me").
  final int cheers;

  /// Increments when the child earns a new sticker for this item.
  final int stickers;

  /// Increments when this item completes its set (row or section).
  final int completions;

  bool get playing => phase == LessonPhase.iDo;

  LearnCardState copyWith({
    LessonPhase? phase,
    int? highlighted,
    bool clearHighlight = false,
    int? revealed,
    bool? reacting,
    int? weDoTarget,
    bool clearWeDoTarget = false,
    HintLevel? hint,
    int? celebrations,
    int? counted,
    int? cheers,
    int? stickers,
    int? completions,
  }) => LearnCardState(
    phase: phase ?? this.phase,
    highlighted: clearHighlight ? null : highlighted ?? this.highlighted,
    revealed: revealed ?? this.revealed,
    reacting: reacting ?? this.reacting,
    weDoTarget: clearWeDoTarget ? null : weDoTarget ?? this.weDoTarget,
    hint: hint ?? this.hint,
    celebrations: celebrations ?? this.celebrations,
    counted: counted ?? this.counted,
    cheers: cheers ?? this.cheers,
    stickers: stickers ?? this.stickers,
    completions: completions ?? this.completions,
  );
}

/// Runs one learn card the way young children learn best: short, warm,
/// multi-sensory, with lots of repetition and a turn for the child.
///
/// 1. **I do**: "Look!" → the name ("A for Apple!", or the animal's name
///    then "Listen to the cow!" + its sound, or counting "1, 2, 3") → a
///    one-line fun fact → letter-by-letter spelling → "Say it with me…
///    Apple!" with a quiet pause for the child to echo → "Yay!".
/// 2. **We do** (first visit to a section only): "Now let's spell it
///    together!"; each letter glows in turn and the child taps it.
/// 3. **You do**: "Where is the apple? Can you tap it?" (later visits: no
///    prompt, just idle hints); the child taps it and Kido praises.
///
/// No "wrong" answers: tapping another letter just says that letter. Idle
/// hints escalate gently (look → point + "Here it is!" → glow). With sound
/// off or a missing clip, every step still runs silently on a timer.
class LearnCardController extends Notifier<LearnCardState> {
  LearnCardController(this.itemId);

  final String itemId;
  int _run = 0;

  /// The set this card belongs to, for stickers and set completion.
  ItemScope? _scope;
  bool _disposed = false;
  late final HintTimer _hints = HintTimer(onLevel: _onHint);

  LearningItem? get _item =>
      ref.read(contentCatalogProvider).value?.itemById(itemId);
  AudioService get _audio => ref.read(audioServiceProvider);
  List<ContentLanguage> get _languages =>
      ref.read(settingsProvider).language.languages;

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

  /// Tells the card which set (section or numbers row) it is shown in.
  void attach(ItemScope scope) => _scope = scope;

  /// Opens the card: full guidance on the first visit to a section.
  Future<void> start() async {
    final item = _item;
    if (item == null) return;
    await playLesson(
      fullGuidance: ref.read(kidoMemoryProvider).fullGuidance(item.section),
    );
  }

  /// Runs (or restarts) the lesson from "I do".
  Future<void> playLesson({bool fullGuidance = false}) async {
    final item = _item;
    if (item == null) return;
    final run = ++_run;
    _hints.stop();
    final tiles = item.spelling;
    final words = _words(item);

    state = state.copyWith(
      phase: LessonPhase.iDo,
      clearHighlight: true,
      clearWeDoTarget: true,
      hint: HintLevel.none,
      counted: 0,
    );

    // Attention.
    await _kidoSay(KidoEvent.look, run);
    if (!_alive(run)) return;

    // Name it.
    if (item.section == SectionId.abc && item.letter != null) {
      // "A for Apple" in English (the letters are the goal), then the
      // Hindi word when bilingual.
      await _kidoSay(
        KidoEvent.letterFor,
        run,
        languages: const [ContentLanguage.en],
        item: item,
        letterAudio: tiles.first.audioAsset,
      );
      if (!_alive(run)) return;
      if (_languages.contains(ContentLanguage.hi)) {
        await _speak([item.voiceHi], run);
      }
    } else {
      await _speak(words, run);
    }
    if (!_alive(run)) return;

    // Hear it: animals and birds.
    if (item.sound case final sound?) {
      await _kidoSay(KidoEvent.listenSound, run, item: item);
      if (!_alive(run)) return;
      state = state.copyWith(reacting: true);
      await _speak([sound], run);
      if (!_alive(run)) return;
      state = state.copyWith(reacting: false);
    }

    // Count it: small numbers.
    final n = item.number;
    if (n != null && n <= AppDurations.countAlongMax) {
      await _countTo(n, run);
      if (!_alive(run)) return;
      await _speak(words, run);
      if (!_alive(run)) return;
    }

    // Know something about it.
    // The fact in Kido's talk language only (Hindi when bilingual).
    final facts = [
      for (final l in ref.read(settingsProvider).language.talkLanguages)
        ?item.factVoice(l),
    ];
    if (facts.isNotEmpty) {
      await _speak(facts, run);
      if (!_alive(run)) return;
    }

    // Spell it: tiles appear and light up letter by letter.
    final voiced = _voicedIndexes(item);
    await _speak(
      [for (final i in voiced) tiles[i].audioAsset!],
      run,
      onSegment: (k) {
        if (!_alive(run)) return;
        state = state.copyWith(
          highlighted: voiced[k],
          revealed: math.max(state.revealed, voiced[k] + 1),
        );
      },
    );
    if (!_alive(run)) return;
    state = state.copyWith(clearHighlight: true, revealed: tiles.length);

    // Say it together, with a quiet moment for the child's turn.
    await _kidoSay(KidoEvent.sayWithMe, run);
    if (!_alive(run)) return;
    await _speak(words, run);
    if (!_alive(run)) return;
    await Future<void>.delayed(AppDurations.echoPause);
    if (!_alive(run)) return;
    state = state.copyWith(cheers: state.cheers + 1);
    await _kidoSay(KidoEvent.yay, run);
    if (!_alive(run)) return;

    if (fullGuidance && voiced.isNotEmpty) {
      await _kidoSay(KidoEvent.spellTogether, run);
      if (!_alive(run)) return;
      state = state.copyWith(phase: LessonPhase.weDo, weDoTarget: voiced.first);
      _hints.start();
    } else {
      await _startYouDo(run, prompt: fullGuidance);
    }
  }

  /// Child tapped a letter tile.
  Future<void> tapLetter(int index) async {
    final item = _item;
    if (item == null) return;
    final audio = item.spelling[index].audioAsset;
    if (audio == null) return;

    if (state.phase == LessonPhase.weDo) {
      await _weDoTap(item, index, audio);
      return;
    }

    // Anywhere else: stop what's playing and just say that letter.
    final run = ++_run;
    final wasYouDo = state.phase == LessonPhase.youDo;
    _hints.stop();
    state = state.copyWith(
      phase: wasYouDo ? LessonPhase.youDo : LessonPhase.done,
      highlighted: index,
      revealed: item.spelling.length,
      reacting: false,
      counted: 0,
    );
    await _speak([audio], run);
    if (!_alive(run)) return;
    state = state.copyWith(clearHighlight: true);
    if (wasYouDo) _hints.start();
  }

  Future<void> _weDoTap(LearningItem item, int index, String audio) async {
    final run = _run; // Taps continue the "we do" flow, not restart it.
    final target = state.weDoTarget;
    state = state.copyWith(highlighted: index, hint: HintLevel.none);
    await _speak([audio], run);
    if (!_alive(run) || state.phase != LessonPhase.weDo) return;

    if (index != target) {
      // A different letter: say it, no "wrong", keep the same target.
      state = state.copyWith(clearHighlight: true);
      return;
    }

    final next = _voicedIndexes(item).where((i) => i > index).firstOrNull;
    if (next != null) {
      state = state.copyWith(clearHighlight: true, weDoTarget: next);
      return;
    }

    _hints.stop();
    state = state.copyWith(clearHighlight: true, clearWeDoTarget: true);
    await _speak(_words(item), run);
    if (!_alive(run)) return;
    await _kidoSay(KidoEvent.praise, run);
    if (!_alive(run)) return;
    await _startYouDo(run, prompt: true);
  }

  Future<void> _startYouDo(int run, {required bool prompt}) async {
    state = state.copyWith(phase: LessonPhase.youDo, hint: HintLevel.none);
    if (prompt) {
      await _kidoSay(KidoEvent.findIt, run, item: _item);
      if (!_alive(run)) return;
    }
    _hints.start();
  }

  /// Child tapped the picture: completes "you do", otherwise replays.
  Future<void> tapPicture() async {
    if (state.phase != LessonPhase.youDo) {
      await playLesson();
      return;
    }
    final run = ++_run;
    _hints.stop();
    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(
      phase: LessonPhase.done,
      hint: HintLevel.none,
      celebrations: state.celebrations + 1,
    );

    final item = _item;
    final scope =
        _scope ?? (item == null ? null : (section: item.section, row: null));
    var completed = false;
    if (item != null && scope != null) {
      final result = await ref
          .read(progressProvider.notifier)
          .markLearned(item, scope);
      if (!_alive(run)) return;
      completed = result.completedScope;
      state = state.copyWith(
        stickers: state.stickers + (result.newSticker ? 1 : 0),
      );
    }

    await _kidoSay(KidoEvent.praise, run);
    if (!_alive(run) || !completed || scope == null) return;

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
  }

  /// Any tap anywhere on the screen: hints go away and the clock restarts.
  void userTapped() => _hints.reset();

  void _onHint(HintLevel level) {
    if (_disposed) return;
    state = state.copyWith(hint: level);
    if (level != HintLevel.point) return;
    final item = _item;
    if (item == null) return;
    // "Tap A!" during we do, "Here it is! Tap the apple!" during you do.
    final target = state.phase == LessonPhase.weDo ? state.weDoTarget : null;
    unawaited(
      target != null
          ? _kidoSay(
              KidoEvent.tapLetter,
              _run,
              itemAudio: item.spelling[target].audioAsset,
            )
          : _kidoSay(KidoEvent.hintTap, _run, item: item),
    );
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
    if (_alive(run)) state = state.copyWith(counted: 0);
  }

  /// Plays [assets]; if nothing could be heard (muted or missing audio),
  /// steps through the segments silently so the visuals keep their rhythm.
  Future<void> _speak(
    List<String> assets,
    int run, {
    void Function(int index)? onSegment,
  }) async {
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
          languages: languages,
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
