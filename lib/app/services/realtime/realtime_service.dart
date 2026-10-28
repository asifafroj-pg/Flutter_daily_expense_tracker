import 'dart:async';

/// Polls a [tick] on a fixed interval while a live screen is visible
/// (realtime.md §4). The bloc still owns state — the poller only refreshes.
class RealtimePoller {
  /// Creates with an [interval] and async [tick] callback.
  RealtimePoller({
    required this.interval,
    required this.tick,
  });

  /// Time between ticks.
  final Duration interval;

  /// Called on every tick; must be cancellation-safe.
  final Future<void> Function() tick;

  Timer? _timer;
  bool _running = false;

  /// Whether the poller is currently scheduled.
  bool get isRunning => _running;

  /// Starts periodic ticking (idempotent; cancels any previous timer).
  void start() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(interval, (_) {
      if (_running) tick();
    });
  }

  /// Stops ticking. Safe to call multiple times.
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }
}
