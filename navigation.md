# Navigation

**This is the routing convention for the app.** go_router is the engine, but it is wrapped so routes are centralized and never scattered through widgets.

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

---

## 1. The three pieces

| Piece | File | Responsibility |
|-------|------|----------------|
| `AppPages` | `lib/app/core/router/app_pages.dart` | Every route path constant |
| `NavigationService` | `lib/app/core/router/navigation_service.dart` | Singleton wrapper over GoRouter |
| `SmartExit` | `lib/app/shared/widgets/smart_exit.dart` | Central back-button handling |

## 2. AppPages — the route registry

`abstract final class` storing all route constants and parameterized helpers.

```dart
abstract final class AppPages {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const settings = '/settings';
  static String itemDetail(String id) => '/items/$id';
  static String profile(String id) => '/profile/$id';
}
```

Rules:
- Path names are kebab-case and lowercase.
- Every path here must have a matching route in `app_router.dart`.
- Parameterized helpers take identity only.

## 3. NavigationService — the only way to navigate

```dart
final class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  NavigationService._internal();

  static NavigationService get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  GoRouter? _router;

  void init(GoRouter router) => _router = router;

  static Future<T?>? navigateTo<T>(String routeName, {Object? extra}) =>
      NavigationService.instance._goRouter.push<T>(routeName, extra: extra);

  static Future<T?>? navigateToReplacement<T>(String routeName, {Object? extra}) =>
      NavigationService.instance._goRouter.pushReplacement<T>(routeName, extra: extra);

  static Future<T?>? navigateToUntilReplacement<T>(String routeName, {Object? extra}) {
    NavigationService.instance._goRouter.go(routeName, extra: extra);
    return null;
  }

  static void goBack<T>([T? result]) {
    if (NavigationService.instance._goRouter.canPop()) {
      NavigationService.instance._goRouter.pop<T>(result);
    }
  }
}
```

Use this everywhere. Widgets should not navigate directly with `context.go` or `Navigator.push`.

## 4. SmartExit — back-button guard

Wrap a screen or shell in a `PopScope` that handles home/back behavior in one place.

## 5. Wiring the router

```dart
GoRouter buildRouter(AuthBloc authBloc) => GoRouter(
  navigatorKey: NavigationService.instance.navigatorKey,
  initialLocation: AppPages.splash,
  refreshListenable: BlocStreamListenable(authBloc.stream),
  redirect: (context, state) {
    final auth = authBloc.state;
    final loc = state.matchedLocation;

    if (auth is AuthUnknown) return loc == AppPages.splash ? null : AppPages.splash;
    if (auth is AuthUnauthenticated) return loc == AppPages.login ? null : AppPages.login;
    if (loc == AppPages.login || loc == AppPages.splash) return AppPages.home;
    return null;
  },
  routes: [
    GoRoute(path: AppPages.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppPages.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppPages.home, builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/items/:id', builder: (_, s) => ItemDetailScreen(id: s.pathParameters['id']!)),
  ],
);
```

## 6. Usage rules

| Intent | Call |
|--------|------|
| Open detail screen | `NavigationService.navigateTo(AppPages.itemDetail(id))` |
| Replace current screen | `NavigationService.navigateToReplacement(AppPages.home)` |
| Reset the stack | `NavigationService.navigateToUntilReplacement(AppPages.login)` |
| Back one screen | `NavigationService.goBack()` |

## 7. Parameters & args

- Identity travels in the path (`AppPages.itemDetail(id)`).
- Transient objects can travel via `extra`, but a screen must never require it.
- Deep links and cold starts must still work without `extra` payloads.

## 8. Auth gate & 401

- The router `redirect` is the authority for auth flow.
- On `401`, clear auth state and redirect to login.
- Do not duplicate the auth gate imperatively in multiple places.

## 9. Anti-patterns

- ❌ `context.go('/items/$id')` in widgets
- ❌ `Navigator.push` for app route changes
- ❌ Hard-coded route strings across the codebase
- ❌ A route without a matching `AppPages` constant
- ❌ Bypassing `SmartExit` on home screens
