import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/kido_line.dart';
import '../../content/models/learning_item.dart';
import '../../content/models/section.dart';
import '../../content/repository/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/haptics/haptics.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/item_picture.dart';
import '../../core/widgets/section_background.dart';
import '../kido/kido_controller.dart';
import '../kido/kido_voice.dart';
import '../kido/kido_widget.dart';

/// "Tap & Play" for the youngest (1–3): a tap anywhere pops up an animal,
/// bird or vehicle right under the finger; it wiggles to its real sound,
/// Kido names it, and it floats away. No right or wrong, no reading: pure
/// cause and effect.
class TapPlayScreen extends ConsumerStatefulWidget {
  const TapPlayScreen({this.random, super.key});

  final math.Random? random;

  @override
  ConsumerState<TapPlayScreen> createState() => _TapPlayScreenState();
}

class _Pop {
  _Pop(this.item, this.at, this.born, this.color);

  final LearningItem item;
  final Offset at;
  final Duration born;
  final Color color;
}

class _TapPlayScreenState extends ConsumerState<TapPlayScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final math.Random _random = widget.random ?? math.Random();
  final _pops = <_Pop>[];
  Duration _now = Duration.zero;
  List<LearningItem>? _pool;
  int _colour = 0;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(kidoControllerProvider.notifier).act(KidoAction.wave);
      unawaited(ref.read(kidoVoiceProvider).say(KidoEvent.tapPlay));
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    _now = elapsed;
    final before = _pops.length;
    _pops.removeWhere((p) => _now - p.born > AppDurations.tapPlayLife);
    if (_pops.isNotEmpty || before != _pops.length) setState(() {});
  }

  List<LearningItem> _items() => _pool ??= () {
    final catalog = ref.read(contentCatalogProvider).value;
    if (catalog == null) return <LearningItem>[];
    return [
      for (final s in [SectionId.animals, SectionId.birds, SectionId.vehicles])
        ...catalog.itemsFor(s),
    ];
  }();

  void _tap(Offset at) {
    final items = _items();
    if (items.isEmpty) return;
    var item = items[_random.nextInt(items.length)];
    // Not the same friend twice in a row.
    if (_pops.isNotEmpty && _pops.last.item.id == item.id && items.length > 1) {
      item = items[(items.indexOf(item) + 1) % items.length];
    }
    setState(() {
      if (_pops.length >= TapPlayScreenLimits.maxPops) _pops.removeAt(0);
      _pops.add(
        _Pop(
          item,
          at,
          _now,
          AppColors.confetti[_colour++ % AppColors.confetti.length],
        ),
      );
    });
    final audio = ref.read(audioServiceProvider);
    audio.playSfx(Sfx.pop);
    ref.read(hapticsProvider).tap();
    final lang = ref.read(settingsProvider).language.languages.first;
    // Its sound, then its name ("Moo!… Cow!").
    unawaited(
      audio.playVoiceSequence([?item.sound, item.voice(lang)], debounce: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // The whole screen is the toy.
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: 'Tap & Play',
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _tap(e.localPosition),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.max(
                          AppSpacing.minTapTarget * 1.3,
                          constraints.maxHeight * 0.38,
                        );
                        return Stack(
                          children: [
                            for (final p in _pops)
                              _popped(p, size, constraints, reduceMotion),
                          ],
                        );
                      },
                    ),
                  ),
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

  Widget _popped(_Pop p, double size, BoxConstraints area, bool reduceMotion) {
    final age =
        (_now - p.born).inMilliseconds /
        AppDurations.tapPlayLife.inMilliseconds;
    // Pop in (elastic), wiggle, then float up and fade.
    final popIn = reduceMotion
        ? 1.0
        : Curves.elasticOut.transform((age / 0.25).clamp(0.0, 1.0));
    final leaving = ((age - 0.7) / 0.3).clamp(0.0, 1.0);
    final wiggle = reduceMotion || age > 0.7
        ? 0.0
        : math.sin(age * math.pi * 14) * 0.08;
    final rise = reduceMotion ? 0.0 : leaving * size * 0.8;
    final left = (p.at.dx - size / 2).clamp(0.0, area.maxWidth - size);
    final top = (p.at.dy - size / 2 - rise).clamp(-size, area.maxHeight - size);
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: 1 - leaving,
          child: Transform.rotate(
            angle: wiggle,
            child: Transform.scale(
              scale: popIn,
              child: ItemPicture(
                image: p.item.image,
                fallbackText: p.item.wordEn,
                accent: p.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class TapPlayScreenLimits {
  /// Most friends on screen at once (the oldest leaves first).
  static const maxPops = 5;
}
