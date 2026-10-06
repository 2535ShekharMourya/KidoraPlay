import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// The privacy policy, in the app's language (Parent Area). The same text
/// is in docs/privacy-policy.md for the Play Store listing.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  /// A paragraph whose short first line is its heading.
  static const _headingMax = 40;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paragraphs = l10n.privacyPolicyBody.split('\n\n');
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final p in paragraphs) ...[
            if (p.contains('\n') && p.indexOf('\n') < _headingMax) ...[
              Text(p.substring(0, p.indexOf('\n')), style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(p.substring(p.indexOf('\n') + 1), style: text.bodyMedium),
            ] else
              Text(p, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
