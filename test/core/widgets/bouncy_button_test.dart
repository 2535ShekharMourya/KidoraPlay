import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidoraplay/core/settings/app_settings.dart';
import 'package:kidoraplay/core/storage/local_store.dart';
import 'package:kidoraplay/core/theme/app_tokens.dart';
import 'package:kidoraplay/core/widgets/bouncy_button.dart';

import '../../helpers/fake_audio.dart';
import '../../helpers/pump_app.dart';

Widget button({VoidCallback? onPressed}) => Center(
  child: BouncyButton(
    semanticLabel: 'Cow',
    onPressed: onPressed,
    child: const SizedBox(width: 40, height: 40),
  ),
);

double currentScale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(BouncyButton),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getMaxScaleOnAxis();

void main() {
  testWidgets('tap calls onPressed and gives a light haptic', (tester) async {
    final haptics = recordHaptics(tester);
    var taps = 0;
    await pumpApp(tester, button(onPressed: () => taps++));

    await tester.tap(find.byType(BouncyButton));
    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await tester.pumpAndSettle();
  });

  testWidgets('tap plays the pop sound once, even when mashed', (tester) async {
    final audio = FakeAudio();
    await pumpApp(tester, button(onPressed: () {}), audio: audio);
    await tester.tap(find.byType(BouncyButton));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(BouncyButton));
    await tester.pump();
    expect(audio.sfxNames, ['pop']);
    await tester.pumpAndSettle();
  });

  testWidgets('rapid repeated taps within 250 ms are ignored', (tester) async {
    var taps = 0;
    await pumpApp(tester, button(onPressed: () => taps++));
    final target = find.byType(BouncyButton);

    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(target);
    expect(taps, 1);

    await tester.pump(AppDurations.tapDebounce);
    await tester.tap(target);
    expect(taps, 2);
    await tester.pumpAndSettle();
  });

  testWidgets('no haptic when vibration is turned off', (tester) async {
    final haptics = recordHaptics(tester);
    await pumpApp(
      tester,
      button(onPressed: () {}),
      store: LocalStore.inMemory({SettingsKeys.vibration: false}),
    );
    await tester.tap(find.byType(BouncyButton));
    expect(haptics, isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('bounces above 1.0 then settles back', (tester) async {
    await pumpApp(tester, button(onPressed: () {}));
    await tester.tap(find.byType(BouncyButton));
    await tester.pump(); // Starts the animation clock.
    await tester.pump(const Duration(milliseconds: 110));
    expect(currentScale(tester), greaterThan(1.05));
    await tester.pumpAndSettle();
    expect(currentScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('reduced motion: no bounce, action still runs', (tester) async {
    var taps = 0;
    await pumpApp(tester, button(onPressed: () => taps++), reduceMotion: true);
    await tester.tap(find.byType(BouncyButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(taps, 1);
    expect(currentScale(tester), 1.0);
  });

  testWidgets('disabled button gives no feedback', (tester) async {
    final haptics = recordHaptics(tester);
    await pumpApp(tester, button());
    await tester.tap(find.byType(BouncyButton));
    expect(haptics, isEmpty);
  });

  testWidgets('is at least 96 dp and labelled for TalkBack', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, button(onPressed: () {}));
    final size = tester.getSize(find.byType(BouncyButton));
    expect(size.width, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    expect(size.height, greaterThanOrEqualTo(AppSpacing.minTapTarget));
    expect(
      tester.getSemantics(find.byType(BouncyButton)),
      matchesSemantics(
        label: 'Cow',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}
