import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'content/repository/content_repository.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Errors are logged locally only (no crash-reporting SDKs). The child must
  // never see an error screen, so release builds render an empty box instead.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const SizedBox.shrink();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final store = await LocalStore.open();
  final container = ProviderContainer(
    overrides: [localStoreProvider.overrideWithValue(store)],
  );

  // Preload content. In debug builds a content mistake stops startup with a
  // list of every problem; in release we log and let screens fall back.
  try {
    await container.read(contentCatalogProvider.future);
  } catch (e, s) {
    if (kDebugMode) rethrow;
    debugPrint('Content failed to load: $e\n$s');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KidoraApp(),
    ),
  );
}
