import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/level.dart';
import '../../core/audio/audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../kido/kido_voice.dart';
import 'story.dart';

@immutable
class StoryState {
  const StoryState({
    this.page = 0,
    this.narrating = false,
    this.atEnd = false,
    this.celebrations = 0,
  });

  final int page;

  /// The page is being read aloud (the next arrow waits to glow).
  final bool narrating;

  /// "The End" is showing.
  final bool atEnd;

  /// Increments when a story is finished.
  final int celebrations;

  StoryState copyWith({
    int? page,
    bool? narrating,
    bool? atEnd,
    int? celebrations,
  }) => StoryState(
    page: page ?? this.page,
    narrating: narrating ?? this.narrating,
    atEnd: atEnd ?? this.atEnd,
    celebrations: celebrations ?? this.celebrations,
  );
}

/// Reads a picture story aloud, a page at a time. The child turns the
/// pages (the arrow glows when a page has been read); tapping the
/// picture reads it again.
class StoryController extends Notifier<StoryState> {
  StoryController(this.storyId);

  final String storyId;
  Story? _story;
  int _run = 0;

  AudioService get _audio => ref.read(audioServiceProvider);

  /// Stories are read in Kido's talk language (Hindi when bilingual).
  ContentLanguage get language =>
      ref.read(settingsProvider).language.talkLanguages.first;

  @override
  StoryState build() {
    final audio = _audio;
    ref.onDispose(() {
      _run++;
      unawaited(audio.stopVoice(owner: this));
    });
    return const StoryState();
  }

  /// Opens [story]: its title, then the first page.
  Future<void> open(Story story) async {
    _story = story;
    state = const StoryState();
    final run = ++_run;
    state = state.copyWith(narrating: true);
    await _audio.playVoiceSequence(
      [story.titleVoice(language), story.pages.first.voice(language)],
      debounce: false,
      owner: this,
    );
    if (run == _run && ref.mounted) state = state.copyWith(narrating: false);
  }

  Future<void> next() async {
    final story = _story;
    if (story == null) return;
    if (state.atEnd) return;
    if (state.page < story.pages.length - 1) {
      await _show(state.page + 1);
      return;
    }
    // The end: a cheer, and Kido asks if they liked it.
    _run++;
    _audio.playSfx(Sfx.cheer);
    state = state.copyWith(
      atEnd: true,
      narrating: false,
      celebrations: state.celebrations + 1,
    );
    await ref.read(kidoVoiceProvider).say(KidoEvent.storyEnd, owner: this);
  }

  Future<void> previous() async {
    if (state.atEnd) {
      await _show(state.page);
      return;
    }
    if (state.page > 0) await _show(state.page - 1);
  }

  /// Reads the current page again (tap on the picture).
  Future<void> replay() => _show(state.page);

  /// Back to the first page.
  Future<void> again() async {
    final story = _story;
    if (story != null) await open(story);
  }

  Future<void> _show(int page) async {
    final story = _story;
    if (story == null) return;
    final run = ++_run;
    state = state.copyWith(page: page, atEnd: false, narrating: true);
    await _audio.playVoiceSequence(
      [story.pages[page].voice(language)],
      debounce: false,
      owner: this,
    );
    if (run == _run && ref.mounted) state = state.copyWith(narrating: false);
  }
}

final storyControllerProvider = NotifierProvider.autoDispose
    .family<StoryController, StoryState, String>(StoryController.new);
