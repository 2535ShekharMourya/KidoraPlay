import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/big_back_button.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/section_background.dart';
import '../../l10n/app_localizations.dart';
import '../kido/kido_widget.dart';
import 'kido_room_controller.dart';

/// Kido's Room: Kido big in the middle. Tap him (head: a pat, tummy: a
/// tickle, trunk: a trumpet), feed him fruit, give him a bath, try on hats.
class KidoRoomScreen extends ConsumerStatefulWidget {
  const KidoRoomScreen({super.key});

  @override
  ConsumerState<KidoRoomScreen> createState() => _KidoRoomScreenState();
}

class _KidoRoomScreenState extends ConsumerState<KidoRoomScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: AppDurations.roomFeed,
  );
  late final AnimationController _bubbles = AnimationController(
    vsync: this,
    duration: AppDurations.roomBath,
  );
  final _random = math.Random();
  List<Offset> _bubbleSpots = const [];

  KidoRoomController get _controller =>
      ref.read(kidoRoomControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.hello());
    });
  }

  @override
  void dispose() {
    _flight.dispose();
    _bubbles.dispose();
    super.dispose();
  }

  void _react(KidoRoomState? prev, KidoRoomState next) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (next.feeds > (prev?.feeds ?? 0)) {
      _flight.forward(from: reduceMotion ? 1 : 0);
    }
    if (next.baths > (prev?.baths ?? 0)) {
      setState(() {
        _bubbleSpots = [
          for (var i = 0; i < 14; i++)
            Offset(_random.nextDouble(), _random.nextDouble()),
        ];
      });
      _bubbles.forward(from: reduceMotion ? 1 : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(kidoRoomControllerProvider, _react);
    final state = ref.watch(kidoRoomControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SectionBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Kido: as tall as fits, centred between the side columns.
              final kidoH = constraints.maxHeight * 0.92;
              final kidoW = math.min(
                kidoH * AppLayout.kidoAspect,
                constraints.maxWidth - AppLayout.sideZone * 2,
              );
              final kido = Rect.fromLTWH(
                (constraints.maxWidth - kidoW) / 2,
                constraints.maxHeight - kidoH,
                kidoW,
                kidoH,
              );
              final mouth = kido.topLeft + Offset(kidoW * 0.70, kidoH * 0.53);
              final feedButton = Offset(
                constraints.maxWidth - AppLayout.sideZone / 2,
                constraints.maxHeight * 0.2,
              );
              return Stack(
                children: [
                  // Kido: tap where you like.
                  Positioned.fromRect(
                    rect: kido,
                    child: Semantics(
                      button: true,
                      label: l10n.roomKido,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => unawaited(
                          _controller.touch(
                            KidoSpot.at(
                              Offset(
                                d.localPosition.dx / kidoW,
                                d.localPosition.dy / kidoH,
                              ),
                            ),
                          ),
                        ),
                        child: const KidoWidget(),
                      ),
                    ),
                  ),
                  // His hat.
                  if (state.hat case final hat?)
                    Positioned(
                      left: kido.left + kidoW * 0.60 - kidoH * 0.18,
                      top: kido.top - kidoH * 0.04,
                      width: kidoH * 0.36,
                      height: kidoH * 0.30,
                      child: IgnorePointer(
                        child: PopIn(
                          key: ValueKey(hat),
                          child: Image.asset(hat.image, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  // A fruit flying into his mouth.
                  if (state.food case final food?)
                    AnimatedBuilder(
                      animation: _flight,
                      builder: (context, _) {
                        final t = Curves.easeInOut.transform(_flight.value);
                        if (_flight.isCompleted || _flight.isDismissed) {
                          return const SizedBox.shrink();
                        }
                        final size = AppSpacing.minTapTarget * (1 - 0.6 * t);
                        // An arc from the button to the mouth.
                        final p =
                            Offset.lerp(feedButton, mouth, t)! -
                            Offset(0, math.sin(t * math.pi) * 60);
                        return Positioned(
                          left: p.dx - size / 2,
                          top: p.dy - size / 2,
                          width: size,
                          height: size,
                          child: IgnorePointer(
                            child: ClipOval(
                              child: Image.asset(food.image, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
                  // Bath bubbles rising around him.
                  AnimatedBuilder(
                    animation: _bubbles,
                    builder: (context, _) {
                      if (_bubbles.isCompleted || _bubbles.isDismissed) {
                        return const SizedBox.shrink();
                      }
                      final t = _bubbles.value;
                      return Stack(
                        children: [
                          for (final (i, s) in _bubbleSpots.indexed)
                            Positioned(
                              left: kido.left + s.dx * kidoW - 24,
                              top:
                                  kido.top +
                                  kidoH * (0.9 - (t + s.dy * 0.5) % 1 * 0.9),
                              width: 36.0 + (i % 3) * 14,
                              height: 36.0 + (i % 3) * 14,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 1 - t,
                                  child: Image.asset(
                                    'assets/images/room/bubbles.webp',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: BigBackButton(),
                  ),
                  // Feed, bath, hats.
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.sm,
                        children: [
                          _RoomButton(
                            label: l10n.roomFeed,
                            image: 'assets/images/room/banana.webp',
                            color: AppColors.fruitsAccent,
                            onPressed: _controller.feed,
                          ),
                          _RoomButton(
                            label: l10n.roomBath,
                            image: 'assets/images/room/soap.webp',
                            color: AppColors.daysAccent,
                            onPressed: _controller.bath,
                          ),
                          _RoomButton(
                            label: l10n.roomHat,
                            image: 'assets/images/room/crown.webp',
                            color: AppColors.monthsAccent,
                            onPressed: _controller.nextHat,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoomButton extends StatelessWidget {
  const _RoomButton({
    required this.label,
    required this.image,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String image;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      semanticLabel: label,
      sfx: null,
      onPressed: onPressed,
      child: Container(
        width: AppSpacing.minTapTarget,
        height: AppSpacing.minTapTarget,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: AppStroke.thick),
        ),
        child: ClipOval(child: Image.asset(image, fit: BoxFit.cover)),
      ),
    );
  }
}
