import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kido_line.dart';
import '../models/learning_item.dart';
import '../models/section.dart';
import 'content_catalog.dart';
import 'content_validator.dart';

const _sectionsFile = 'assets/content/sections.json';
const _kidoLinesFile = 'assets/content/kido_lines.json';

/// Loads and caches all learning content from bundled JSON assets.
///
/// In debug builds the content is validated on load and any mistake throws a
/// [ContentValidationException] listing every problem.
class ContentRepository {
  ContentRepository({required this._bundle, this._validate = kDebugMode});

  final AssetBundle _bundle;
  final bool _validate;
  Future<ContentCatalog>? _cache;

  Future<ContentCatalog> load() => _cache ??= _load().catchError(
        (Object e) {
          _cache = null; // Allow a retry after a failure.
          throw e;
        },
      );

  Future<ContentCatalog> _load() async {
    final sectionsJson = await _readJson(_sectionsFile);
    if (sectionsJson is! List<dynamic>) {
      throw const FormatException('sections.json: expected a JSON list');
    }
    final sections = [for (final s in sectionsJson) Section.fromJson(s)];

    final items = <SectionId, List<LearningItem>>{};
    for (final section in sections) {
      final file = section.itemsFile.split('/').last;
      final json = await _readJson(section.itemsFile);
      if (json is! List<dynamic>) {
        throw FormatException('$file: expected a JSON list');
      }
      items[section.id] = [
        for (final i in json) LearningItem.fromJson(i, file: file),
      ];
    }

    final catalog = ContentCatalog(
      sections: sections,
      items: items,
      kidoLines: KidoLines.fromJson(await _readJson(_kidoLinesFile)),
    );

    if (_validate) {
      final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
      final errors =
          validateContent(catalog, assets: manifest.listAssets().toSet());
      if (errors.isNotEmpty) throw ContentValidationException(errors);
    }
    return catalog;
  }

  Future<Object?> _readJson(String path) async {
    final text = await _bundle.loadString(path);
    try {
      return jsonDecode(text);
    } on FormatException catch (e) {
      throw FormatException('$path: invalid JSON: ${e.message}');
    }
  }
}

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(bundle: rootBundle),
);

/// The loaded content. Preloaded during startup in `main()`.
final contentCatalogProvider = FutureProvider<ContentCatalog>(
  (ref) => ref.watch(contentRepositoryProvider).load(),
);
