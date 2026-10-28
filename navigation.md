# Navigation (go_router + AppPages + NavigationService + SmartExit)

**This is the routing convention for Parafleet. There is no other way to
navigate.** go_router is the engine, but it is wrapped so that:

1. **Routes are never string literals** — they live in one registry: `AppPages`.
2. **Widgets never call `context.go` / `context.push` / `Navigator.push`** —
   navigation goes through the single `NavigationService`.
3. **Back is handled centrally** by `SmartExit`.

## Contents

1. [The three pieces](#1-the-three-pieces)
2. [AppPages — the route registry](#2-apppages--the-route-registry)
3. [NavigationService — the only way to navigate](#3-navigationservice--the-only-way-to-navigate)
4. [SmartExit — back-button guard](#4-smartexit--back-button-guard)
5. [Wiring the router](#5-wiring-the-router)
6. [Usage rules](#6-usage-rules)
7. [Parameters & args](#7-parameters--args)
8. [Auth gate & 401](#8-auth-gate--401)
9. [Anti-patterns](#9-anti-patterns)
10. [Testing navigation](#10-testing-navigation)

---

## 1. The three pieces

| Piece | File | Responsibility |
|-------|------|----------------|
| `AppPages` | `lib/app/core/router/app_pages.dart` | **Every** route path as a constant, plus `String` builders for parameterised routes. |
| `NavigationService` | `lib/app/core/router/navigation_service.dart` | Singleton wrapper over `GoRouter`: guarded push / replace / go / pop. Holds the `navigatorKey`. |
| `SmartExit` | `lib/app/shared/widgets/smart_exit.dart` | `PopScope` back-handling: exit dialog on the home screen, custom behaviour elsewhere. |

The route **table** (`GoRoute` builders, redirects) lives in
`lib/app/core/router/app_router.dart` and references `AppPages` constants for its
paths — never inline strings.

## 2. AppPages — the route registry

`abstract final class` (never instantiated). Fixed paths are `static const`;
routes with identity use a `static String` builder.

```dart
// lib/app/core/router/app_pages.dart
abstract final class AppPages {
  // ── Root / auth ──────────────────────────────────────────────
  static const splash = '/splash';
  static const login = '/login';

  // ── Shell tabs ───────────────────────────────────────────────
  static const dashboard = '/dashboard';
  static const trips = '/trips';
  static const fleet = '/fleet';
  static const more = '/more';

  // ── Trips ────────────────────────────────────────────────────
  static String tripDetail(String id) => '/trips/$id';
  static String tripReport(String id) => '/trips/$id/report';

  // ── Fleet (nested under /fleet) ──────────────────────────────
  static const vehicles = '/fleet/vehicles';
  static const vehicleNew = '/fleet/vehicles/new';
  static String vehicleDetail(String id) => '/fleet/vehicles/$id';
  static String vehicleEdit(String id) => '/fleet/vehicles/$id/edit';

  static const drivers = '/fleet/drivers';
  static const driverNew = '/fleet/drivers/new';
  static String driverDetail(String id) => '/fleet/drivers/$id';
  static String driverEdit(String id) => '/fleet/drivers/$id/edit';

  static const documents = '/fleet/documents';

  // ── Tenders & quotations ─────────────────────────────────────
  static const tenders = '/more/tenders';
  static String tenderDetail(String id) => '/more/tenders/$id';
  static const quotationNew = '/more/quotations/new';
  static String quotationDetail(String id) => '/more/quotations/$id';

  // ── Rates / assignments / bills / claims / performance ───────
  static const rates = '/more/rates';
  static String rateDetail(String id) => '/more/rates/$id';

  static const assignments = '/more/assignments';
  static String assignmentDetail(String id) => '/more/assignments/$id';

  static const bills = '/more/bills';
  static String billDetail(String id) => '/more/bills/$id';

  static const claims = '/more/claims';
  static const claimNew = '/more/claims/new';
  static String claimDetail(String id) => '/more/claims/$id';

  static const performance = '/more/performance';

  // ── Notifications ────────────────────────────────────────────
  static const notifications = '/notifications';
  static String notificationDetail(String id) => '/notifications/$id';

  // ── Account / settings ───────────────────────────────────────
  static const profile = '/more/profile';
  static const vendorInfo = '/more/settings/vendor-info';
  static const users = '/more/users';
  static String userDetail(String id) => '/more/users/$id';
  static const roles = '/more/roles';
  static const settings = '/more/settings';
  static const language = '/more/settings/language';
  static const appInfo = '/more/settings/app-info';
}
```

**Rules**

- Path names are **kebab-case, lowercase, plural for collections**
  (`/more/profit-loss`, `/fleet/vehicles`).
- Every path here must have a matching `GoRoute` in `app_router.dart` (and vice
  versa). A path with no route, or a route with no constant, is a bug.
- Nested/secondary screens live under their section (`/more/...`), not flat.
- Parameterised helpers take **identity only** (`id`) — keep the route
  deep-linkable.

## 3. NavigationService — the only way to navigate

A singleton wrapping `GoRouter`. It exposes a `navigatorKey` (for
context-free navigation and dialogs), initialises once with the router, and
provides the navigation verbs. Pushes are **double-tap-guarded** (a 400 ms
window) so a rapid double tap can't push the same location twice and crash with
`!keyReservation.contains(key)`.

```dart
// lib/app/core/router/navigation_service.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  NavigationService._internal();

  static NavigationService get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  GoRouter? _router;

  /// Rapid double-taps that would push the same location twice onto the same
  /// navigator are suppressed with a short debounce window. (A pop-based lock
  /// would deadlock routes kept alive on a shell/IndexedStack branch.)
  static final Map<String, DateTime> _lastPushAt = {};
  static const Duration _doubleTapWindow = Duration(milliseconds: 400);

  void init(GoRouter router) => _router = router;

  GoRouter get _goRouter {
    final router = _router;
    if (router == null) {
      throw StateError('GoRouter not initialized. Call NavigationService.init() first.');
    }
    return router;
  }

  static Future<T?>? _pushGuarded<T>(String routeName, {Object? extra}) {
    final now = DateTime.now();
    final last = _lastPushAt[routeName];
    if (last != null && now.difference(last) <= _doubleTapWindow) return null;
    _lastPushAt[routeName] = now;
    return NavigationService.instance._goRouter.push<T>(routeName, extra: extra);
  }

  /// Push a new screen onto the stack (detail screens, drill-downs).
  static Future<T?>? navigateTo<T>(String routeName, {Object? extra}) =>
      _pushGuarded<T>(routeName, extra: extra);

  /// Replace the current screen (e.g. splash/login → dashboard). No back to it.
  static Future<T?>? navigateToReplacement<T>(String routeName, {Object? extra}) =>
      NavigationService.instance._goRouter.pushReplacement<T>(routeName, extra: extra);

  /// Reset the whole stack to [routeName] (logout → login, "go home").
  static Future<T?>? navigateToUntilReplacement<T>(String routeName, {Object? extra}) {
    NavigationService.instance._goRouter.go(routeName, extra: extra);
    return null;
  }

  /// Push with a typed argument object (`extra`).
  static Future<T?>? navigateToWithArgs<T>(String routeName, Object? args) =>
      _pushGuarded<T>(routeName, extra: args);

  /// Replace the top of the stack with [routeName] (returns a result to caller).
  static Future<T?>? popAndReplace<T>(String routeName, {Object? extra}) =>
      NavigationService.instance._goRouter.pushReplacement<T>(routeName, extra: extra);

  /// Pop the top screen, returning an optional [result].
  static void goBack<T>([T? result]) {
    if (NavigationService.canGoBack()) {
      NavigationService.instance._goRouter.pop<T>(result);
    }
  }

  static bool canGoBack() => NavigationService.instance._goRouter.canPop();

  /// Alias of [goBack] — pops only when there is something to pop.
  static void safeBack<T>([T? result]) {
    if (NavigationService.canGoBack()) {
      NavigationService.instance._goRouter.pop<T>(result);
    }
  }

  /// A `BuildContext` for code that has none (dialogs, snackbars).
  static BuildContext? get context => NavigationService.instance.navigatorKey.currentContext;
}
```

## 4. SmartExit — back-button guard

Wraps a screen (or a shell) in a `PopScope` so the system back button is handled
in one place: **home screen → exit confirmation**; **other screens →
`onBackHome`** (usually pop, or switch to the dashboard tab).

```dart
// lib/app/shared/widgets/smart_exit.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central back-button guard.
///
/// - On a home screen (`isHome: true`) back shows an exit confirmation dialog;
///   "yes" exits the app, "no" stays.
/// - On any other screen (`isHome: false`) back calls [onBackHome].
class SmartExit extends StatelessWidget {
  const SmartExit({
    super.key,
    required this.child,
    this.isHome = true,
    this.onBackHome,
    this.exitTitle = 'Exit?',
    this.exitMessage = 'Do you want to exit the app?',
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
  });

  final Widget child;
  final bool isHome;
  final VoidCallback? onBackHome;
  final String exitTitle;
  final String exitMessage;
  final String yesLabel;
  final String noLabel;

  Future<void> _handleBack(BuildContext context) async {
    if (!isHome) {
      onBackHome?.call();
      return;
    }
    final shouldExit = await _confirmExit(context);
    if (shouldExit && context.mounted) SystemNavigator.pop();
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(exitTitle),
        content: Text(exitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(noLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(yesLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: child,
    );
  }
}
```

> Pass localised labels (ARB) from the calling screen — the class defaults are
> English placeholders.

## 5. Wiring the router

`app_router.dart` builds the single `GoRouter`, hands it the service's
`navigatorKey`, references `AppPages` for every path, owns the auth `redirect`,
and registers itself with the service.

```dart
// lib/app/core/router/app_router.dart
GoRouter buildRouter(AuthBloc authBloc) => GoRouter(
      navigatorKey: NavigationService.instance.navigatorKey,
      initialLocation: AppPages.splash,
      refreshListenable: BlocStreamListenable(authBloc.stream), // Stream<State> → Listenable
      redirect: (context, state) {
        final auth = authBloc.state;
        final loc = state.matchedLocation;

        if (auth is AuthUnknown) return loc == AppPages.splash ? null : AppPages.splash;
        if (auth is AuthUnauthenticated) return loc == AppPages.login ? null : AppPages.login;
        // authenticated:
        if (loc == AppPages.login || loc == AppPages.splash) return AppPages.dashboard;
        return null; // permission guards go here (see security.md)
      },
      routes: [
        GoRoute(path: AppPages.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppPages.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppPages.dashboard, builder: (_, __) => const DashboardScreen()),

        // Parameterised route — path param carries identity
        GoRoute(
          path: '/trips/:id',
          builder: (_, s) => TripDetailScreen(id: s.pathParameters['id']!),
        ),

        // Nested section
        GoRoute(
          path: AppPages.vehicles,
          builder: (_, __) => const VehicleListScreen(),
          routes: [
            GoRoute(path: 'new', builder: (_, __) => const VehicleFormScreen()),
            GoRoute(
              path: ':id',
              builder: (_, s) => VehicleDetailScreen(id: s.pathParameters['id']!),
            ),
          ],
        ),
      ],
      errorBuilder: (_, __) => const NotFoundScreen(),
    );
```

In `app.dart` (or `main.dart`), **initialise the service the moment the router is
created**:

```dart
final router = buildRouter(sl<AuthBloc>());
NavigationService.instance.init(router);
// ...MaterialApp.router(routerConfig: router, ...)
```

## 6. Usage rules

**Widgets never navigate themselves. Call the service, then use `AppPages`.**

| Intent | Call |
|--------|------|
| Open a detail/drill-down screen | `NavigationService.navigateTo(AppPages.tripDetail(id))` |
| Replace current screen (no back) | `NavigationService.navigateToReplacement(AppPages.dashboard)` |
| Reset the stack to a root (logout, go home) | `NavigationService.navigateToUntilReplacement(AppPages.login)` |
| Push with a typed object | `NavigationService.navigateToWithArgs(AppPages.vehicleEdit(id), vehicle)` |
| Replace the top, return a result | `NavigationService.popAndReplace(AppPages.suppliers)` |
| Back one screen | `NavigationService.goBack()` / `NavigationService.safeBack()` |
| Can we go back? | `NavigationService.canGoBack()` |

```dart
// From a widget callback
onTap: () => NavigationService.navigateTo(AppPages.tripDetail(trip.id)),

// After a successful mutation (push results back to the caller)
NavigationService.goBack(true);

// After login / logout
NavigationService.navigateToUntilReplacement(AppPages.dashboard);
NavigationService.navigateToUntilReplacement(AppPages.login);
```

**Choose push vs replace vs go:**

- **push** — the user should be able to come back (lists → detail → edit).
- **pushReplacement** — the current screen must not be returned to (splash →
  home, OTP → dashboard).
- **go** (reset) — clear the whole stack (logout, "start over", deep-link reset).

Inside a `BlocListener` (e.g. `AuthBloc` → navigate on success), use
`NavigationService`, **not** `context.go`. The service is context-free, so it
also works from services/notifications.

## 7. Parameters & args

- **Identity travels in the path** (`AppPages.tripDetail(id)`); the builder reads
  `state.pathParameters['id']`. This keeps routes deep-linkable and shareable.
- **Transient objects** (a freshly-fetched entity to prefill a form) may travel
  via `extra` (`navigateToWithArgs`) — but a screen must **never require**
  `extra`. On `null`, refetch by id. A deep link or a process death must not
  break the screen.
- `extra` is not type-checked by the router: cast it safely at the builder
  (`final v = state.extra as VehicleEntity?;`) and fall back to a fetch.

## 8. Auth gate & 401

- The **`redirect`** in `app_router.dart` is the authority for the auth gate: it
  decides splash / login / dashboard from `AuthBloc` state, covering cold start,
  deep links and 401. It runs on every navigation once wired with
  `refreshListenable`.
- On **401**, the `AuthInterceptor` resets `AuthBloc` to `AuthUnauthenticated`
  (clearing storage + cache); the redirect then lands the user on
  `AppPages.login`. See [`security.md`](security.md) and
  [`architecture.md`](architecture.md) §7.
- Imperative navigation (`NavigationService.navigateToReplacement(...)`) is for
  *in-flow* transitions (e.g. after an explicit login submit). Don't duplicate
  the auth gate imperatively.

## 9. Anti-patterns

- ❌ `context.go('/trips/$id')` / `context.push(...)` in a widget — use
  `NavigationService` + `AppPages`.
- ❌ `Navigator.push(context, MaterialPageRoute(...))` for app pages — only
  `Navigator.of(dialogContext).pop()` is allowed (for dialogs/bottom sheets).
- ❌ Raw path strings anywhere outside `app_pages.dart` and `app_router.dart`.
- ❌ A screen that breaks when `extra` is `null` (deep link / cold start).
- ❌ Bypassing `SmartExit` on a home/tab screen (unguarded back = accidental
  exit).
- ❌ Adding a route without an `AppPages` constant (or vice versa).
- ❌ Rebuilding the whole `GoRouter` on each auth change — use
  `refreshListenable`.

## 10. Testing navigation

- Build the real router in a widget test with a fake `AuthBloc`; tap a control;
  `expect(find.byType(TripDetailScreen), findsOneWidget)`.
- Assert parameterised builders receive the right `pathParameters`.
- Test the redirect matrix (unknown → splash, unauthenticated → login,
  authenticated → dashboard).
- Test the double-tap guard: two `navigateTo(sameRoute)` calls in < 400 ms push
  **once**.
- Test `SmartExit`: `isHome: true` shows the dialog; `isHome: false` calls
  `onBackHome`.
