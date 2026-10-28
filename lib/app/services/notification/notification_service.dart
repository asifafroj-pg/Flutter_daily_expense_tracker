import 'dart:async';

/// Push-notification seam (realtime.md §3). A push tells the app *what*
/// changed; listeners trigger a targeted refresh, never a full state replace.
///
/// Wire FCM to this contract when the product adds push; keeping it abstract
/// avoids a hard plugin dependency in the base scaffold.
abstract class NotificationService {
  /// Stream of change topics pushed by the server, e.g. `items/42`.
  Stream<String> get onResourceChanged;

  /// Requests notification permission and initialises the provider.
  Future<void> init();

  /// Tears down subscriptions.
  void dispose();
}

/// In-memory implementation used until a real push provider is configured.
class NoopNotificationService implements NotificationService {
  /// Creates the no-op service.
  NoopNotificationService();

  final StreamController<String> _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get onResourceChanged => _controller.stream;

  @override
  Future<void> init() async {}

  @override
  void dispose() => _controller.close();

  /// Test hook: emit a change topic as if a push arrived.
  void simulatePush(String topic) {
    if (!_controller.isClosed) _controller.add(topic);
  }
}
