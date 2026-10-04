import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value store for all app state. Everything stays on the device;
/// nothing here ever leaves it.
class LocalStore {
  LocalStore(SharedPreferencesWithCache prefs) : _backend = _PrefsBackend(prefs);

  /// In-memory store for tests and previews.
  LocalStore.inMemory([Map<String, Object> initial = const {}])
      : _backend = _MemoryBackend({...initial});

  final _Backend _backend;

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return LocalStore(prefs);
  }

  bool getBool(String key, {bool fallback = false}) =>
      _backend.get(key) as bool? ?? fallback;

  Future<void> setBool(String key, {required bool value}) =>
      _backend.set(key, value);

  String? getString(String key) => _backend.get(key) as String?;

  Future<void> setString(String key, String value) => _backend.set(key, value);
}

abstract interface class _Backend {
  Object? get(String key);
  Future<void> set(String key, Object value);
}

class _PrefsBackend implements _Backend {
  _PrefsBackend(this._prefs);

  final SharedPreferencesWithCache _prefs;

  @override
  Object? get(String key) => _prefs.get(key);

  @override
  Future<void> set(String key, Object value) => switch (value) {
        final bool v => _prefs.setBool(key, v),
        final String v => _prefs.setString(key, v),
        final int v => _prefs.setInt(key, v),
        final double v => _prefs.setDouble(key, v),
        _ => throw ArgumentError.value(value, key, 'unsupported type'),
      };
}

class _MemoryBackend implements _Backend {
  _MemoryBackend(this._values);

  final Map<String, Object> _values;

  @override
  Object? get(String key) => _values[key];

  @override
  Future<void> set(String key, Object value) async => _values[key] = value;
}

/// Overridden in `main()` once the store has been opened.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);
