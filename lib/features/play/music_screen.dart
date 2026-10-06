import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/particle_burst.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_voice.dart';
import '../kido/kido_widget.dart';
import '../path/daily_path.dart';
import 'toys.dart';

/// Music toy: a rainbow xylophone in a pentatonic scale, so every tune a
/// toddler taps sounds nice. Kido dances along.
class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  /// Notes that complete Music as a step on the daily path.
  static const stepNotes = 8;

  /// Notes from low to high (see tool/make_notes.py).
  static const notes = [
    'assets/audio/music/notes/note_0.m4a',
    'assets/audio/music/notes/note_1.m4a',
    'assets/audio/music/notes/note_2.m4a',
    'assets/audio/music/notes/note_3.m4a',
    'assets/audio/music/notes/note_4.m4a',
    'assets/audio/music/notes/note_5.m4a',
    'assets/audio/music/notes/note_6.m4a',
  ];

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  final _bursts = List.generate(
    MusicScreen.notes.length,
    (_) => BurstController(),
  );
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(audioServiceProvider).preloadNotes(MusicScreen.notes));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(kidoControllerProvider.notifier).act(KidoAction.wave);
      unawaited(ref.read(kidoVoiceProvider).say(KidoEvent.musicStart));
    });
  }

  @override
  void dispose() {
    for (final b in _bursts) {
      b.dispose();
    }
    super.dispose();
  }

  void _play(int i) {
    final audio = ref.read(audioServiceProvider);
    // Kido stops talking once the music starts.
    if (_taps++ == 0) unawaited(audio.stopVoice());
    audio.playNote(MusicScreen.notes[i]);
    // A little tune counts as today's toy step.
    if (_taps == MusicScreen.stepNotes) {
      unawaited(
        ref
            .read(dailyPathProvider.notifier)
            .completed(PathStep(PathKind.toy, ToyKind.music.name)),
      );
    }
    ref.read(hapticsProvider).tap();
    _bursts[i].fire();
    // Kido dances: a clap now and then.
    if (_taps % 3 == 0) {
      ref.read(kidoControllerProvider.notifier).act(KidoAction.clap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.sideZone,
                  vertical: AppSpacing.md,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = AppSpacing.sm;
                    // As many bars as fit at a child-friendly width (5–7).
                    final n =
                        ((constraints.maxWidth + gap) /
                                (AppSpacing.minTapTarget + gap))
                            .floor()
                            .clamp(5, MusicScreen.notes.length);
                    final width = (constraints.maxWidth - gap * (n - 1)) / n;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var i = 0; i < n; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: width,
                            // Low notes are long bars, high notes short.
                            height:
                                constraints.maxHeight *
                                (1 - 0.35 * i / math.max(1, n - 1)),
                            child: PopIn(
                              index: i,
                              child: ParticleBurst(
                                controller: _bursts[i],
                                child: BouncyButton(
                                  semanticLabel: 'Note ${i + 1}',
                                  sfx: null,
                                  sparkle: false,
                                  onPressed: () => _play(i),
                                  child: _Bar(
                                    color:
                                        AppColors.confetti[i %
                                            AppColors.confetti.length],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const Align(alignment: Alignment.topLeft, child: BigBackButton()),
              const KidoCorner(),
            ],
          ),
        ),
      ),
    );
  }
}

/// One xylophone bar: bright, rounded, with two pegs.
class _Bar extends StatelessWidget {
  const _Bar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline, width: AppStroke.thick),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var k = 0; k < 2; k++)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                width: AppSpacing.md,
                height: AppSpacing.md,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
