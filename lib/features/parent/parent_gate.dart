import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'parent_gate_logic.dart';

/// Grown-ups-only check shown before anything that is not learning
/// content (settings, purchases, links). A wrong answer brings a new,
/// different challenge.
class ParentGate extends StatefulWidget {
  const ParentGate({
    required this.onPassed,
    required this.onCancel,
    this.random,
    super.key,
  });

  final VoidCallback onPassed;
  final VoidCallback onCancel;

  /// Injectable for tests.
  final math.Random? random;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate>
    with SingleTickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late GateChallenge _challenge = GateChallenge.random(_random);
  bool _wrong = false;

  late final AnimationController _hold =
      AnimationController(vsync: this, duration: HoldChallenge.holdFor)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onPassed();
        });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _choose(NumberChallenge challenge, int choice) {
    if (challenge.isCorrect(choice)) {
      widget.onPassed();
      return;
    }
    setState(() {
      _wrong = true;
      _challenge = GateChallenge.random(_random);
      _hold.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cream,
      // Landscape: title and Cancel on the left, the task on the right.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: AppSpacing.xxl,
                      color: AppColors.outline,
                    ),
                    Text(
                      l10n.parentGateTitle,
                      style: text.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_wrong) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.gateTryAgain,
                        textAlign: TextAlign.center,
                        style: text.titleLarge?.copyWith(
                          fontSize: 16,
                          color: AppColors.birdsAccent,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: widget.onCancel,
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: switch (_challenge) {
                    HoldChallenge() => _holdTask(l10n, text),
                    final NumberChallenge c => _numberTask(c, l10n, text),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _holdTask(AppLocalizations l10n, TextTheme text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.gateHold,
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Listener(
          // The gate may already be gone when the finger lifts (it closes
          // the moment the hold completes), hence the mounted checks.
          onPointerDown: (_) => mounted ? _hold.forward() : null,
          onPointerUp: (_) => mounted ? _hold.reverse() : null,
          onPointerCancel: (_) => mounted ? _hold.reverse() : null,
          child: Semantics(
            button: true,
            label: l10n.gateHoldButton,
            child: SizedBox.square(
              dimension: AppSpacing.minTapTarget,
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, child) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _hold.value,
                      strokeWidth: AppStroke.thick * 2,
                      color: AppColors.success,
                      backgroundColor: AppColors.outline.withValues(
                        alpha: 0.15,
                      ),
                    ),
                    child!,
                  ],
                ),
                child: Center(
                  child: Text(l10n.gateHoldButton, style: text.titleLarge),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberTask(
    NumberChallenge challenge,
    AppLocalizations l10n,
    TextTheme text,
  ) {
    final word = l10n.gateNumberWords.split(',')[challenge.answer - 1];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.gateTapNumber(word),
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            for (final n in challenge.options)
              SizedBox.square(
                dimension: AppSpacing.xxl * 1.4,
                child: FilledButton.tonal(
                  key: ValueKey('gate-option-$n'),
                  onPressed: () => _choose(challenge, n),
                  child: Text('$n', style: text.headlineMedium),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
