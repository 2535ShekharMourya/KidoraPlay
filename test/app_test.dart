import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/app.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/features/home/home_screen.dart';
import 'package:kidoraplay/features/splash/splash_screen.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // Landscape phone size.
    binding.platformDispatcher.views.first.physicalSize = const Size(2400, 1080);
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  testWidgets('starts on splash, then shows home with 4 sections',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KidoraApp()));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(AppDurations.splash);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('ABC'), findsOneWidget);
    expect(find.text('Animals'), findsOneWidget);
    expect(find.text('Birds'), findsOneWidget);
  });

  testWidgets('section tiles meet the 96 dp minimum tap target',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KidoraApp()));
    await tester.pump(AppDurations.splash);
    await tester.pumpAndSettle();

    for (final label in ['Numbers', 'ABC', 'Animals', 'Birds']) {
      final tile = find.ancestor(
        of: find.text(label),
        matching: find.byType(Container),
      );
      final size = tester.getSize(tile.first);
      expect(size.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    }
  });
}
