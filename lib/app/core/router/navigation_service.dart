import 'package:flutter/widgets.dart';

/// Centralised navigation helpers around `go_router` (navigation.md §3):
/// screens never call `context.go` directly with raw path strings — they use
/// [AppPages] constants + this service, so routes stay typed and greppable.
class NavigationService {
  NavigationService._();

  /// Singleton instance registered in DI.
  static final NavigationService instance = NavigationService._();

  /// Set once by the router bootstrap; used for imperative navigation from
  /// non-widget code (e.g. the 401 handler).
  late GlobalKey<NavigatorState> rootNavigatorKey;

  /// Safely pops the top route; no-op when there is nothing to pop.
  void maybePop() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      unawaited(navigator.pop());
    }
  }
}
