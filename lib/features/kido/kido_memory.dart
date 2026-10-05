import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/section.dart';
import '../../core/storage/local_store.dart';
import '../../content/models/kido_line.dart';
import '../../content/repository/content_repository.dart';
import 'kido_controller.dart';
import 'kido_voice.dart';

/// What Kido remembers (on the device only) so he talks less over time.
class KidoMemory {
  KidoMemory(this._store);

  final LocalStore _store;

  // Guidance decided when a section is entered, for this visit.
  final _fullGuidance = <SectionId, bool>{};
  bool _greetedThisSession = false;

  static const _welcomedKey = 'kido.welcomed';
  static String _visitedKey(SectionId id) => 'kido.visited.${id.name}';

  /// Has Kido ever said his first-time welcome?
  bool get welcomed => _store.getBool(_welcomedKey);

  Future<void> markWelcomed() => _store.setBool(_welcomedKey, value: true);

  /// Kido greets once per app session; returns true the first time.
  bool takeSessionGreeting() {
    if (_greetedThisSession) return false;
    return _greetedThisSession = true;
  }

  bool visited(SectionId id) => _store.getBool(_visitedKey(id));

  /// Call when the child enters a section. The first visit ever gets full
  /// guidance (I do → we do → you do with narration); later visits get a
  /// short version with hints only when idle.
  Future<void> enterSection(SectionId id) async {
    _fullGuidance[id] = !visited(id);
    await _store.setBool(_visitedKey(id), value: true);
  }

  bool fullGuidance(SectionId id) => _fullGuidance[id] ?? !visited(id);

  static const _discoveredKey = 'kido.discovered';

  /// Has the child found out that tapping a picture reveals more? Until
  /// then Kido explains it; afterwards he never repeats it.
  bool get discovered => _store.getBool(_discoveredKey);

  Future<void> markDiscovered() async {
    if (!discovered) await _store.setBool(_discoveredKey, value: true);
  }
}

final kidoMemoryProvider = Provider<KidoMemory>(
  (ref) => KidoMemory(ref.watch(localStoreProvider)),
);

/// Records a section visit. The first time, Kido waves and says
/// "Let's learn Animals!".
Future<void> enterSection(WidgetRef ref, SectionId id) async {
  final memory = ref.read(kidoMemoryProvider);
  final first = !memory.visited(id);
  await memory.enterSection(id);
  if (!first) return;
  ref.read(kidoControllerProvider.notifier).act(KidoAction.wave);
  final section = ref.read(contentCatalogProvider).value?.section(id);
  await ref
      .read(kidoVoiceProvider)
      .say(KidoEvent.sectionIntro, section: section);
}
