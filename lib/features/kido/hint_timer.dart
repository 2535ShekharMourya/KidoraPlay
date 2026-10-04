import 'dart:async';

/// How strongly Kido is hinting at the target.
enum HintLevel {
  none,

  /// 5 s idle: Kido looks toward the target.
  look,

  /// 10 s idle: Kido points with his trunk and says "Tap the …!".
  point,

  /// 15 s idle: the target glows and bounces.
  glow,
}

/// Escalating hints while the child is idle. Any tap calls [reset].
///
/// After the glow, the cycle starts over, but hints never repeat more than
/// [maxCycles] times in a row; then Kido waits quietly for the next tap.
class HintTimer {
  HintTimer({
    required this.onLevel,
    this.lookAfter = const Duration(seconds: 5),
    this.pointAfter = const Duration(seconds: 10),
    this.glowAfter = const Duration(seconds: 15),
    this.maxCycles = 2,
  });

  final void Function(HintLevel level) onLevel;
  final Duration lookAfter;
  final Duration pointAfter;
  final Duration glowAfter;
  final int maxCycles;

  Timer? _timer;
  int _cycles = 0;
  bool _running = false;
  HintLevel _level = HintLevel.none;

  bool get isRunning => _running;
  HintLevel get level => _level;

  void start() {
    _running = true;
    _cycles = 0;
    _restartCycle();
  }

  /// The child tapped something: hints go away and the clock restarts.
  void reset() {
    if (!_running) return;
    _cycles = 0;
    _restartCycle();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _set(HintLevel.none);
  }

  void _restartCycle() {
    _timer?.cancel();
    _set(HintLevel.none);
    _after(lookAfter, () {
      _set(HintLevel.look);
      _after(pointAfter - lookAfter, () {
        _set(HintLevel.point);
        _after(glowAfter - pointAfter, () {
          _set(HintLevel.glow);
          _cycles++;
          if (_cycles < maxCycles) {
            _after(lookAfter, _restartCycleKeepingCount);
          }
        });
      });
    });
  }

  void _restartCycleKeepingCount() {
    final cycles = _cycles;
    _restartCycle();
    _cycles = cycles;
  }

  void _after(Duration d, void Function() then) {
    _timer = Timer(d, () {
      if (_running) then();
    });
  }

  void _set(HintLevel level) {
    if (_level == level) return;
    _level = level;
    onLevel(level);
  }
}
