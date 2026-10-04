import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/section_theme.dart';
import '../../core/widgets/beckon.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../core/widgets/wiggle.dart';
import '../../l10n/app_localizations.dart';
import '../kido/hint_timer.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_widget.dart';
import '../progress/sticker_widgets.dart';
import 'games_screen.dart';
import 'quiz_controller.dart';
import 'quiz_models.dart';

/// One practice game: progress stars on top, the question (spoken, with a
/// "hear again" button), the choices, and Kido helping.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({required this.kind, super.key});

  final GameKind kind;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _answerKey = GlobalKey();

  QuizController get _controller =>
      ref.read(quizControllerProvider(widget.kind).notifier);
  KidoController get _kido => ref.read(kidoControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  Offset? _answerCenter() {
    final box = _answerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _directKido(QuizState? prev, QuizState next) {
    if (next.games > (prev?.games ?? 0)) {
      _kido.act(KidoAction.trumpet);
    } else if (next.solved > (prev?.solved ?? 0)) {
      _kido.act(KidoAction.clap);
    } else if (next.answerGlows && !(prev?.answerGlows ?? false)) {
      _kido.act(KidoAction.point, target: _answerCenter());
    } else if (next.hint == HintLevel.look && prev?.hint != HintLevel.look) {
      _kido.act(KidoAction.look, target: _answerCenter());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizControllerProvider(widget.kind));
    ref.listen(quizControllerProvider(widget.kind), _directKido);
    final theme = SectionTheme.of(widget.kind.theme);
    final round = state.round;
    final finished = state.phase == QuizPhase.finished;

    return Scaffold(
      body: Listener(
        onPointerDown: (_) => _controller.userTapped(),
        child: SectionBackground(
          section: widget.kind.theme,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.sideZone,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      _ProgressStars(
                        solved: state.solved,
                        total: math.max(1, state.rounds.length),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (round != null && !finished) ...[
                        if (round.subject != null && round.count != null)
                          _CountingPictures(
                            image: round.subject!.image,
                            count: round.count!,
                          ),
                        Expanded(
                          child: _Choices(
                            key: ValueKey(state.index),
                            round: round,
                            state: state,
                            accent: theme.accent,
                            answerKey: _answerKey,
                            onTap: _controller.tap,
                          ),
                        ),
                      ],
                      if (finished)
                        Expanded(
                          child: Center(
                            child: PopIn(
                              child: BouncyButton(
                                semanticLabel: l10n.playAgain,
                                onPressed: _controller.start,
                                child: _RoundButton(
                                  icon: Icons.replay_rounded,
                                  color: theme.accent,
                                  size: AppSpacing.minTapTarget * 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: BigBackButton(),
                ),
                if (!finished)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: BouncyButton(
                        semanticLabel: l10n.hearAgain,
                        sfx: null,
                        sparkle: false,
                        onPressed: _controller.replayPrompt,
                        child: _RoundButton(
                          icon: Icons.volume_up_rounded,
                          color: theme.accent,
                          size: AppSpacing.minTapTarget,
                        ),
                      ),
                    ),
                  ),
                const KidoCorner(),
                if (state.games > 0 && finished)
                  Positioned.fill(
                    child: CelebrationOverlay(
                      key: ValueKey(state.games),
                      image: GamesScreen.imageFor(widget.kind),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Five stars that fill as rounds are answered. Only ever goes up.
class _ProgressStars extends StatelessWidget {
  const _ProgressStars({required this.solved, required this.total});

  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedScale(
            scale: i < solved ? 1.15 : 1,
            duration: AppDurations.highlight,
            curve: AppCurves.tap,
            child: Icon(
              Icons.star_rounded,
              size: AppSpacing.xl * 1.2,
              color: i < solved
                  ? AppColors.celebrate
                  : AppColors.outline.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }
}

/// "How many?": the picture shown [count] times, in up to two rows.
class _CountingPictures extends StatelessWidget {
  const _CountingPictures({required this.image, required this.count});

  final String image;
  final int count;

  @override
  Widget build(BuildContext context) {
    final perRow = count <= 5 ? count : (count / 2).ceil();
    const size = AppSpacing.xxl * 1.35;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(
              width: math.min(size, 480 / perRow),
              height: size,
              child: PopIn(
                index: i,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.round,
    required this.state,
    required this.accent,
    required this.answerKey,
    required this.onTap,
    super.key,
  });

  final QuizRound round;
  final QuizState state;
  final Color accent;
  final GlobalKey answerKey;
  final void Function(QuizChoice) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = round.choices.length;
        const gap = AppSpacing.tapGap;
        final size = math.max(
          AppSpacing.minTapTarget,
          math.min(
            (constraints.maxWidth - gap * (n - 1)) / n,
            math.min(constraints.maxHeight, 170.0),
          ),
        );
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, choice) in round.choices.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox.square(
                  dimension: size,
                  child: PopIn(
                    index: i,
                    child: Beckon(
                      key: choice == round.answer ? answerKey : null,
                      active: choice == round.answer && state.answerGlows,
                      strong: true,
                      child: Wiggle(
                        key: ValueKey('${choice.id}-${state.wrongSeq}'),
                        active: state.lastWrong == choice.id,
                        child: BouncyButton(
                          semanticLabel: choice.label,
                          sfx: null,
                          sparkle: choice == round.answer,
                          onPressed: () => onTap(choice),
                          child: choice.text != null
                              ? _TextCard(text: choice.text!, accent: accent)
                              : ItemPicture(
                                  image: choice.item!.image,
                                  fallbackText: choice.label,
                                  accent: accent,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: accent, width: AppStroke.thick),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(text, style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      child: Icon(icon, size: size * 0.55, color: AppColors.white),
    );
  }
}
