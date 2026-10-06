/// Strict JSON field access that fails with a message naming the file/item
/// and field, so content mistakes are easy to find.
class JsonReader {
  JsonReader(Object? json, this.context)
    : _json = json is Map<String, dynamic>
          ? json
          : throw FormatException('$context: expected a JSON object');

  final Map<String, dynamic> _json;
  final String context;

  Iterable<String> get keys => _json.keys;

  String string(String key) {
    final value = _json[key];
    if (value is String) return value;
    throw _error(key, 'a string', value);
  }

  String? optString(String key) {
    final value = _json[key];
    if (value == null || value is String) return value as String?;
    throw _error(key, 'a string or null', value);
  }

  int? optInt(String key) {
    final value = _json[key];
    if (value == null || value is int) return value as int?;
    throw _error(key, 'an integer or null', value);
  }

  bool? optBool(String key) {
    final value = _json[key];
    if (value == null || value is bool) return value as bool?;
    throw _error(key, 'true, false or null', value);
  }

  List<String> stringList(String key) {
    final value = _json[key];
    if (value is List<dynamic> && value.every((e) => e is String)) {
      return List.unmodifiable(value.cast<String>());
    }
    throw _error(key, 'a list of strings', value);
  }

  Map<String, dynamic> object(String key) {
    final value = _json[key];
    if (value is Map<String, dynamic>) return value;
    throw _error(key, 'an object', value);
  }

  List<dynamic> list(String key) {
    final value = _json[key];
    if (value is List<dynamic>) return value;
    throw _error(key, 'a list', value);
  }

  FormatException _error(String key, String expected, Object? actual) =>
      FormatException(
        '$context: "$key" must be $expected, got ${actual ?? 'null'}',
      );
}

/// Parses a JSON enum value by its Dart name, with a clear error.
T parseEnum<T extends Enum>(List<T> values, String raw, String context) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  throw FormatException(
    '$context: unknown value "$raw", expected one of '
    '${values.map((v) => v.name).join(', ')}',
  );
}
