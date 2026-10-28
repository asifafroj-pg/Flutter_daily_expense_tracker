import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Contract for network availability. The Data layer consults this before
/// choosing remote paths; the UI shows a non-blocking offline banner
/// (realtime.md §7). Offline *support* remains opt-in per feature.
abstract class ConnectivityService {
  /// Whether at least one non-none interface is connected right now.
  Future<bool> get isConnected;

  /// Stream of connectivity changes for app-shell banners.
  Stream<bool> get onConnectivityChanged;
}

/// Implementation backed by `connectivity_plus`.
class ConnectivityServiceImpl implements ConnectivityService {
  /// Creates with an injectable [connectivity] plugin for tests.
  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.every((r) => r == ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    _sub ??= _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.every((r) => r == ConnectivityResult.none);
      if (!_controller.isClosed) _controller.add(online);
    });
    return _controller.stream;
  }

  /// Stops listening to plugin events; called from DI teardown in tests.
  void dispose() {
    _sub?.cancel();
    _sub = null;
    _controller.close();
  }
}
