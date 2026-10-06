import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/content/models/level.dart';
import 'package:kidoraplay/content/repository/content_catalog.dart';
import 'package:kidoraplay/content/repository/content_repository.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/features/stories/story.dart';
import 'package:kidoraplay/features/stories/story_controller.dart';
import 'package:kidoraplay/features/stories/story_screens.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ContentCatalog catalog;
  late List<Story> stories;
  setUpAll(() async {
    catalog = await loadTestCatalog();
    stories = await loadStories(rootBundle);
  });

  test('ten stories, five pages each, every picture and voice exists', () {
    expect(stories, hasLength(10));
    expect(stories.map((s) => s.id).toSet(), hasLength(10));
    for (final s in stories) {
      expect(s.pages, hasLength(5), reason: s.id);
      for (final asset in s.assets) {
        expect(File(asset).existsSync(), isTrue, reason: '${s.id}: $asset');
      }
    }
    // Every class has stories, babies the gentlest ones.
    for (final level in Level.values) {
      expect(
        stories.where((s) => s.levels.contains(level)).length,
        greaterThanOrEqualTo(4),
        reason: level.name,
      );
    }
  });

  group('reading', () {
    late FakeAudio audio;
    late ProviderContainer c;

    Future<StoryController> open(String language) async {
      audio = FakeAudio();
      c = ProviderContainer(
        overrides: [
          ...testOverrides(
            audio: audio,
            catalog: catalog,
            store: LocalStore.inMemory({SettingsKeys.language: language}),
          ),
          storiesProvider.overrideWith((ref) async => stories),
        ],
      );
      addTearDown(c.dispose);
      await c.read(contentCatalogProvider.future);
      c.listen(storyControllerProvider('thirsty_crow'), (_, _) {});
      final reader = c.read(storyControllerProvider('thirsty_crow').notifier);
      await reader.open(stories.first);
      return reader;
    }

    StoryState state() => c.read(storyControllerProvider('thirsty_crow'));

    test('title, then each page; the end cheers', () async {
      final reader = await open('en');
      expect(audio.voice.played, [
        'assets/audio/en/stories/thirsty_crow_title.m4a',
        'assets/audio/en/stories/thirsty_crow_1.m4a',
      ]);
      expect(state().narrating, isFalse);

      await reader.next();
      expect(state().page, 1);
      expect(
        audio.voice.played.last,
        'assets/audio/en/stories/thirsty_crow_2.m4a',
      );
      await reader.previous();
      expect(state().page, 0);
      await reader.replay();
      expect(
        audio.voice.played.last,
        'assets/audio/en/stories/thirsty_crow_1.m4a',
      );

      for (var i = 0; i < 4; i++) {
        await reader.next();
      }
      expect(state().page, 4);
      await reader.next();
      expect(state().atEnd, isTrue);
      expect(state().celebrations, 1);
      expect(audio.voice.played.last, 'assets/audio/en/kido/story_end.m4a');
      expect(audio.sfxNames, contains('cheer'));

      await reader.again();
      expect(state().atEnd, isFalse);
      expect(state().page, 0);
    });

    test('bilingual: read in Hindi', () async {
      await open('both');
      expect(audio.voice.played, [
        'assets/audio/hi/stories/thirsty_crow_title.m4a',
        'assets/audio/hi/stories/thirsty_crow_1.m4a',
      ]);
    });
  });

  testWidgets('the shelf shows the stories for the child\'s class', (
    tester,
  ) async {
    await pumpApp(
      tester,
      ProviderScope(
        overrides: [storiesProvider.overrideWith((ref) async => stories)],
        child: const StoriesScreen(),
      ),
      catalog: catalog,
      store: LocalStore.inMemory({
        SettingsKeys.language: 'en',
        SettingsKeys.level: 'baby',
      }),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('The Thirsty Crow'), findsOneWidget);
    expect(find.text('The Greedy Dog'), findsNothing); // LKG and up
    await tester.pumpWidget(const SizedBox());
  });
}
