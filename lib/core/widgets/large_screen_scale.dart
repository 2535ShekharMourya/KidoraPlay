import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// On tablets, lays the app out as if on a large phone and scales it up,
/// so pictures, words and buttons fill the screen instead of floating
/// small in empty space. Phones are untouched. Taps scale with it.
class LargeScreenScale extends StatelessWidget {
  const LargeScreenScale({required this.child, super.key});

  final Widget child;

  /// Scale for a screen whose shorter side is [shortestSide] (logical px).
  static double scaleFor(double shortestSide) =>
      (shortestSide / AppLayout.designShortSide).clamp(1.0, AppLayout.maxScale);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = scaleFor(mq.size.shortestSide);
    if (scale <= 1.0) return child;
    final logical = mq.size / scale;
    return MediaQuery(
      data: mq.copyWith(
        size: logical,
        padding: mq.padding / scale,
        viewPadding: mq.viewPadding / scale,
        viewInsets: mq.viewInsets / scale,
        devicePixelRatio: mq.devicePixelRatio * scale,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: logical, child: child),
      ),
    );
  }
}
