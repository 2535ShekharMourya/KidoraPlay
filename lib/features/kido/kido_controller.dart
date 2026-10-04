import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kido's animations. These mirror the inputs of the Rive state machine
/// `KidoMachine` (idle, wave, point + pointAngle, talk, spellTap, clap,
/// trumpet, think, surprised, coverEars) so the placeholder painter can be
/// swapped for the real Rive file without touching callers. `look` turns
/// his head toward a target (first hint level).
enum KidoAction {
  idle,
  wave(Duration(milliseconds: 1400)),
  look,
  point,
  spellTap(Duration(milliseconds: 320)),
  clap(Duration(milliseconds: 1000)),
  trumpet(Duration(milliseconds: 1300)),
  think,
  surprised(Duration(milliseconds: 800)),
  coverEars;

  const KidoAction([this.oneShot]);

  /// One-shot actions return to idle after this long; others hold.
  final Duration? oneShot;
}

@immutable
class KidoState {
  const KidoState({this.action = KidoAction.idle, this.target, this.seq = 0});

  final KidoAction action;

  /// Global screen point Kido looks or points at (null: straight ahead).
  final Offset? target;

  /// Bumps on every action so repeating the same one replays it.
  final int seq;
}

/// Drives Kido. Callers say what Kido does; the widget decides how it
/// looks. Talking is automatic while any voice clip plays.
class KidoController extends Notifier<KidoState> {
  Timer? _revert;

  @override
  KidoState build() {
    ref.onDispose(() => _revert?.cancel());
    return const KidoState();
  }

  void act(KidoAction action, {Offset? target}) {
    _revert?.cancel();
    state = KidoState(action: action, target: target, seq: state.seq + 1);
    if (action.oneShot case final d?) {
      _revert = Timer(d, () => act(KidoAction.idle));
    }
  }

  void idle() {
    if (state.action != KidoAction.idle) act(KidoAction.idle);
  }
}

final kidoControllerProvider =
    NotifierProvider<KidoController, KidoState>(KidoController.new);
