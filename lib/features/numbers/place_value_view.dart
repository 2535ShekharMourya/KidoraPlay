import 'package:flutter/material.dart';

import '../../content/number_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// 21 = two bars of ten + one dot, with the digits underneath, so place
/// value can be seen without reading.
class PlaceValueView extends StatelessWidget {
  const PlaceValueView({
    required this.number,
    required this.tensColor,
    required this.onesColor,
    super.key,
  });

  final int number;
  final Color tensColor;
  final Color onesColor;

  @override
  Widget build(BuildContext context) {
    final (:tens, :ones) = placeValue(number);
    final digitStyle = Theme.of(context).textTheme.headlineMedium;

    Widget group({
      required Widget picture,
      required String digit,
      required Color color,
    }) =>
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            picture,
            const SizedBox(height: AppSpacing.xs),
            Text(digit, style: digitStyle?.copyWith(color: color)),
          ],
        );

    return Semantics(
      label: AppLocalizations.of(context).placeValue(tens, ones),
      excludeSemantics: true,
      child: FittedBox(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            group(
              picture: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (var i = 0; i < tens; i++) _TenBar(color: tensColor),
                ],
              ),
              digit: '$tens',
              color: tensColor,
            ),
            const SizedBox(width: AppSpacing.lg),
            group(
              picture: SizedBox(
                width: _OneDot.size * 3 + AppSpacing.xs * 2,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (var i = 0; i < ones; i++) _OneDot(color: onesColor),
                  ],
                ),
              ),
              digit: '$ones',
              color: onesColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// A column of ten small squares.
class _TenBar extends StatelessWidget {
  const _TenBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.sm / 2),
        border: Border.all(color: AppColors.outline, width: AppStroke.thin),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 10; i++)
            Container(
              width: _OneDot.size * 0.6,
              height: _OneDot.size * 0.6,
              margin: const EdgeInsets.all(1),
              color: color,
            ),
        ],
      ),
    );
  }
}

class _OneDot extends StatelessWidget {
  const _OneDot({required this.color});

  static const size = 18.0;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: AppStroke.thin),
      ),
    );
  }
}
