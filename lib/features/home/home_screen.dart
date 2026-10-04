import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/idle_float.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../content/models/kido_line.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_memory.dart';
import '../kido/kido_voice.dart';
import '../kido/kido_widget.dart';
import '../progress/progress_controller.dart';
import '../progress/sticker_book_screen.dart';
import '../progress/sticker_widgets.dart';

/// Section menu. Kido waves hello (a full welcome the very first time, a
/// short one after that, once per session). Tapping a tile says the
/// section name and opens it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  Future<void> _greet() async {
    final memory = ref.read(kidoMemoryProvider);
    if (!mounted || !memory.takeSessionGreeting()) return;
    final first = !memory.welcomed;
    ref.read(kidoControllerProvider.notifier).act(KidoAction.wave);
    await ref
        .read(kidoVoiceProvider)
        .say(first ? KidoEvent.welcomeFirst : KidoEvent.welcomeBack);
    if (first) await memory.markWelcomed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      SectionId.numbers: l10n.sectionNumbers,
      SectionId.abc: l10n.sectionAbc,
      SectionId.animals: l10n.sectionAnimals,
      SectionId.birds: l10n.sectionBirds,
    };
    final catalog = ref.watch(contentCatalogProvider).value;

    void open(SectionId id) {
      final section = catalog?.section(id);
      // First visit: the section greets with "Let's learn …!" instead.
      if (section != null && ref.read(kidoMemoryProvider).visited(id)) {
        final languages = ref.read(settingsProvider).language.languages;
        ref.read(audioServiceProvider).playVoiceSequence([
          for (final l in languages) section.voice(l),
        ]);
      }
      context.go(AppRoutes.section(id));
    }

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                // The left column is Kido's and the right one holds the
                // sticker book; tiles never sit under either.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.xxl,
                ),
                child: Row(
                  children: [
                    for (final (i, id) in SectionId.values.indexed)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.tapGap / 2),
                          child: PopIn(
                            index: i,
                            child: IdleFloat(
                              phase: i / SectionId.values.length,
                              child: _SectionTile(
                                id: id,
                                label: labels[id]!,
                                image: catalog?.section(id)?.image,
                                onPressed: () => open(id),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Grown-ups' corner: small and plain on purpose; the parent
              // gate behind it keeps children out.
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Semantics(
                    button: true,
                    label: l10n.parentArea,
                    excludeSemantics: true,
                    child: IconButton.filledTonal(
                      iconSize: AppSpacing.xl,
                      onPressed: () => context.go(AppRoutes.parent),
                      icon: const Icon(Icons.lock_rounded),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: BouncyButton(
                    semanticLabel: l10n.stickerBook,
                    onPressed: () => context.go(AppRoutes.stickers),
                    child: StickerJar(
                      count: ref.watch(progressProvider).learned.length,
                    ),
                  ),
                ),
              ),
              const KidoCorner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends ConsumerWidget {
  const _SectionTile({
    required this.id,
    required this.label,
    required this.image,
    required this.onPressed,
  });

  final SectionId id;
  final String label;
  final String? image;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = SectionTheme.of(id);
    final progress = ref.watch(sectionProgressProvider(id));
    return BouncyButton(
      semanticLabel: label,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            if (image != null)
              Expanded(
                child: Image.asset(
                  image!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            StarCountBadge(learned: progress.learned, total: progress.total),
          ],
        ),
      ),
    );
  }
}
