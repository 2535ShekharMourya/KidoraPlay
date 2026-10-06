import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/level.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../billing/billing_controller.dart';
import '../billing/plans_screen.dart';
import '../progress/progress_controller.dart';
import 'parent_gate.dart';

/// Settings for grown-ups, always behind the [ParentGate]. Everything here
/// is stored on the device only.
class ParentAreaScreen extends ConsumerStatefulWidget {
  const ParentAreaScreen({super.key});

  @override
  ConsumerState<ParentAreaScreen> createState() => _ParentAreaScreenState();
}

class _ParentAreaScreenState extends ConsumerState<ParentAreaScreen> {
  bool _unlocked = false;

  void _leave() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return ParentGate(
        onPassed: () => setState(() => _unlocked = true),
        onCancel: _leave,
      );
    }

    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final stickers = ref.watch(progressProvider).learned.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(l10n.parentArea),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _leave,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          children: [
            ListTile(
              leading: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.celebrate,
              ),
              title: Text(l10n.plansEntry),
              subtitle: Text(
                ref.watch(isPremiumProvider)
                    ? l10n.premiumActive
                    : l10n.plansEntryFree,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PlansScreen()),
              ),
            ),
            _Heading(l10n.settingsClass),
            SegmentedButton<Level>(
              segments: [
                ButtonSegment(value: Level.baby, label: Text(l10n.levelBaby)),
                ButtonSegment(
                  value: Level.nursery,
                  label: Text(l10n.levelNursery),
                ),
                ButtonSegment(value: Level.lkg, label: Text(l10n.levelLkg)),
                ButtonSegment(value: Level.ukg, label: Text(l10n.levelUkg)),
              ],
              selected: {settings.level},
              onSelectionChanged: (s) => notifier.setLevel(s.single),
            ),
            _Heading(l10n.settingsLanguage),
            SegmentedButton<LanguageMode>(
              segments: [
                ButtonSegment(
                  value: LanguageMode.en,
                  label: Text(l10n.langEnglish),
                ),
                ButtonSegment(
                  value: LanguageMode.hi,
                  label: Text(l10n.langHindi),
                ),
                ButtonSegment(
                  value: LanguageMode.both,
                  label: Text(l10n.langBoth),
                ),
              ],
              selected: {settings.language},
              onSelectionChanged: (s) => notifier.setLanguage(s.single),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: Text(l10n.settingsSound),
              secondary: const Icon(Icons.volume_up_rounded),
              value: settings.soundEnabled,
              onChanged: notifier.setSoundEnabled,
            ),
            SwitchListTile(
              title: Text(l10n.settingsMusic),
              secondary: const Icon(Icons.music_note_rounded),
              value: settings.musicEnabled,
              onChanged: settings.soundEnabled
                  ? notifier.setMusicEnabled
                  : null,
            ),
            SwitchListTile(
              title: Text(l10n.settingsVibration),
              secondary: const Icon(Icons.vibration_rounded),
              value: settings.vibrationEnabled,
              onChanged: notifier.setVibrationEnabled,
            ),
            _Heading(l10n.progressTitle),
            ListTile(
              leading: const Icon(
                Icons.star_rounded,
                color: AppColors.celebrate,
              ),
              title: Text(l10n.progressStickers(stickers)),
              trailing: TextButton(
                onPressed: stickers == 0 ? null : _confirmReset,
                child: Text(l10n.resetProgress),
              ),
            ),
            _Heading(l10n.aboutTitle),
            ListTile(
              leading: const Icon(
                Icons.shield_rounded,
                color: AppColors.success,
              ),
              title: Text(l10n.privacyNote),
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: Text(l10n.licences),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(progressProvider.notifier).reset();
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}
