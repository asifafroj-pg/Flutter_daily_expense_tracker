# Architecture

**Status: decision (locked).** State management is **BLoC / Cubit**. This is the
reference skill's *Case 4* (Bloc/Cubit + GetIt + TDD), adapted for Parafleet.

## Contents

1. [Core philosophy](#1-core-philosophy)
2. [The three layers](#2-the-three-layers)
3. [Why BLoC (the decision record)](#3-why-bloc-the-decision-record)
4. [Dependency injection — GetIt](#4-dependency-injection--getit)
5. [Error handling — dartz Either](#5-error-handling--dartz-either)
6. [Routing — AppPages + NavigationService](#6-routing--apppages--navigationservice)
7. [Auth, session & roles](#7-auth-session--roles)
8. [Offline-first (summary)](#8-offline-first-summary)
9. [Naming](#9-naming)
10. [Anti-patterns to reject](#10-anti-patterns-to-reject)

---

## 1. Core philosophy

Four non-negotiable foundations. Every other decision flows from these.

1. **Clean Architecture** — strict **Presentation / Domain / Data** separation.
   Domain is pure Dart.
2. **Feature-driven** — code lives in self-contained modules under
   `lib/features/<feature>/`; a feature never reaches into another feature's
   internals.
3. **Dependency rule** — dependencies point **inwards only**:
   `Presentation → Domain ← Data`.
4. **Single responsibility** — one class, one job. If you need two sentences to
   describe it, split it.

## 2. The three layers

```
Presentation  ──▶  Domain  ◀──  Data
  (Bloc/Cubit,      (entities,     (datasources, models,
   screens,          repository     repository impls —
   widgets)          contracts,     the ONLY layer that
                     use cases)     touches Dio/Hive/services)
```

| Layer | May import | Must NOT import |
|-------|-----------|-----------------|
| **Presentation** | Domain (use cases, entities), `flutter_bloc`, `app/shared`, `app/core/theme`, `go_router` | Dio, Hive, datasources, service implementations |
| **Domain** | `dart:core`, `equatable`, `dartz` | Flutter, Dio, Hive, bloc, get_it, anything else |
| **Data** | Domain (to implement contracts), Dio, Hive, secure storage, cache service | Presentation |

A cycle means the design is wrong — refactor.

**Data flow for a read:**
`Screen → Bloc.add(Event) → UseCase.call() → Repository → (Remote|Local)DataSource
→ Either<Failure, Entity> → Bloc emits state → BlocBuilder renders`.

**Data flow for a write:**
`Screen → Bloc.add(Event) → UseCase → Repository → RemoteDataSource
→ on success: invalidate cache + refresh; on offline: enqueue for replay`.

Full folder layout: [`project-structure.md`](project-structure.md).

## 3. Why BLoC (the decision record)

- **Explicit, testable state machines.** Every transition is an event + a
  state, which maps cleanly to how this domain works (a trip moves through
  statuses; a bill is generated then acknowledged).
- **`bloc_test`** gives us the strongest TDD story (given/when/then on emitted
  states) — see [`qa.md`](qa.md).
- **Separation of intent (event) from result (state)** keeps async UI boring and
  predictable, which matters for offline/retry flows.

**Alternatives considered and rejected** (recorded so we don't relitigate):
GetX (too implicit, weak test story), Riverpod + GetIt hybrid (superb, but the
team standardised on event/state separation), role-based Riverpod (this app is
vendor-only — no multi-role shell). One state library, forever: BLoC/Cubit.

**Bloc vs Cubit — choose deliberately, don't default to Bloc:**

| Use | When |
|-----|------|
| **Bloc** | Event-driven flows, multiple typed events, complex transitions, pagination, need an event audit trail. |
| **Cubit** | Simple value/serial state: a nav index, a filter form, a theme toggle, an auth session flag. |

Never force events where a plain `emit` from a method is enough.

## 4. Dependency injection — GetIt

`get_it` is the **only** DI mechanism. One container: `lib/app/core/di/service_locator.dart`.

- **Services** (cache, dio, storage, connectivity, sync, notification) →
  `registerLazySingleton`.
- **Datasources, repositories, use cases** → `registerLazySingleton` (no
  per-screen state).
- **Blocs / Cubits** → `registerFactory` (a fresh instance per screen; avoids
  stale state leaking across screens).
- **App-scoped auth/session bloc** → `registerLazySingleton` (it must outlive
  screens — see §7).

Resolve with `sl<MyBloc>()`, `sl<GetTripsUseCase>()`, etc. Never construct a
dependency with `new` inside a widget.

```dart
// lib/app/core/di/service_locator.dart
final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ── Services (lazy singletons) ──────────────────────────────
  sl.registerLazySingleton<SecureStorage>(() => SecureStorageImpl());
  sl.registerLazySingleton<CacheService>(() => CacheServiceImpl(sl()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityServiceImpl());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl(), sl()));
  sl.registerLazySingleton<OfflineQueue>(() => OfflineQueue(
        dioClient: sl(), cache: sl(), connectivity: sl()));

  // ── Auth (app-scoped) ───────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), storage: sl(), dio: sl()));
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<RestoreSessionUseCase>(() => RestoreSessionUseCase(sl()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(
        login: sl(), restore: sl(), logout: sl()));

  // ── Feature: trips (example) ────────────────────────────────
  sl.registerLazySingleton<TripRemoteDataSource>(
    () => TripRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<TripLocalDataSource>(
    () => TripLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(
        remote: sl(), local: sl(), networkInfo: sl()));
  sl.registerLazySingleton<GetTripsUseCase>(() => GetTripsUseCase(sl()));
  sl.registerLazySingleton<UpdateTripStatusUseCase>(
    () => UpdateTripStatusUseCase(sl()));
  sl.registerFactory<TripListBloc>(() => TripListBloc(
        getTrips: sl(), updateStatus: sl()));

  await sl<CacheService>().init();
}
```

## 5. Error handling — dartz Either

Every Domai/Data method that can fail returns **`Either<Failure, T>`**.
Exceptions are an internal Data-layer detail; the UI never sees a raw exception.

- `app/core/error/exceptions.dart` — `ServerException`, `NetworkException`,
  `CacheException`, `AuthException`, `ValidationException`. **Data sources throw
  these.**
- `app/core/error/failures.dart` — abstract `Failure` + `ServerFailure`,
  `NetworkFailure`, `CacheFailure`, `AuthFailure`, `ValidationFailure`. All
  `extends Equatable`. **Repositories return these inside `Left`.**

**Each layer maps its own exception to its own Failure** — never mix:

```dart
try {
  final raw = await _remote.getTrips(page: page);
  await _local.cache(key, raw, ttl: const Duration(minutes: 5));
  return Right(raw.map(TripModel.fromJson).map((m) => m.toEntity()).toList());
} on ServerException catch (e) {
  final stale = await _local.getStale(key);        // ★ stale-while-offline
  if (stale != null) return Right(_parse(stale));
  return Left(ServerFailure(e.message, statusCode: e.statusCode));
} on NetworkException {
  final stale = await _local.getStale(key);
  if (stale != null) return Right(_parse(stale));
  return const Left(NetworkFailure());
}
```

Blocs `fold` the result: `Left → emit(ErrorState)`, `Right → emit(LoadedState)`.

## 6. Routing — AppPages + NavigationService

go_router is the engine, but it is **wrapped** so routing is centralised and
never scattered through widgets:

- **`AppPages`** (`core/router/app_pages.dart`) — every route path as a
  `static const` (or a `static String` builder for parameterised routes).
  **No route string literal exists anywhere else.**
- **`NavigationService`** (`core/router/navigation_service.dart`) — the singleton
  wrapper: `navigateTo`, `navigateToReplacement`, `navigateToUntilReplacement`,
  `navigateToWithArgs`, `popAndReplace`, `goBack`, `canGoBack`. Holds the
  `navigatorKey` and a 400 ms double-tap guard. **Widgets call this — never
  `context.go` / `context.push`.**
- **`SmartExit`** (`shared/widgets/smart_exit.dart`) — the central `PopScope`
  back guard (exit dialog on home, custom behaviour elsewhere).
- The **route table + auth `redirect`** live in `core/router/app_router.dart`,
  reference `AppPages`, and are driven by `AuthBloc` via a `refreshListenable`
  (splash while restoring → login when unauthenticated → dashboard when
  authenticated).

```dart
// Navigate (in a widget callback or a BlocListener) — never context.go
NavigationService.navigateTo(AppPages.tripDetail(trip.id));
NavigationService.navigateToUntilReplacement(AppPages.login); // logout
```

Full spec, code snippets and rules: **[`navigation.md`](navigation.md)**.

## 7. Auth, session & user permissions

Parafleet serves a **single audience: vendors**. There is no multi-role shell and
no rider/hub modes. Authentication is one vendor login; the authenticated **user**
may carry a role and a set of permissions, used only to show/hide UI.

- The **token** (+ refresh token, user profile, permissions) lives in
  `FlutterSecureStorage`. Write it exactly once, in the repository, on login.
- Restore session **only** by validating with the server (`GET /api/v1/me` or the
  vendor-me endpoint). **Never fabricate a user or permissions** from local storage.
- `AuthBloc` is **app-scoped** (`registerLazySingleton`) — it outlives the router
  and every screen.
- The `AuthInterceptor` injects `Authorization: Bearer <token>` and, on **401**,
  MUST: clear secure storage (and cache), reset `AuthBloc` to
  `AuthUnauthenticated`, and let the router redirect to `/login`.
- **Permissions** come from the server (the API's `x-tms.permissions` list). The
  app may *hide* unauthorized actions; the server *enforces*. A missing/unknown
  permission = **forbidden** — never a default "allowed" fallback.
- Clear the cache (`clearAll`) on login and logout, **awaited before the first
  authenticated screen renders**, so data never leaks between users.

## 8. Real-time & data freshness

Parafleet is a **real-time** app: vendors need live trip status, dispatch
changes, gate/weighbridge events and notifications. Assume connectivity; design
for freshness, not for long periods offline.

- **Push (FCM)** drives events that must arrive without a user action
  (assignment offers, approvals, status changes). Map each payload to a route +
  a targeted refresh (see [`realtime.md`](realtime.md)).
- **Polling / streams** keep live screens current while they are visible:
  refresh on focus/resume, short-TTL polling for hot views (active trips,
  dashboard counters), longer intervals for cold views.
- **Pull-to-refresh** on every collection screen.
- **Optimistic updates with rollback**: apply a mutation locally, reconcile with
  the server response, and roll back + surface a typed error on failure.
- **Light cache for speed, not for offline**: cache reads are a *performance*
  optimization with short TTLs. Do **not** assume cache can substitute for the
  network.

**Offline support is OPT-IN.** Only features explicitly flagged as
offline-capable implement the cache-with-TTL, mutation invalidation and write
queue described in [`offline-optional.md`](offline-optional.md). Everything else
fails fast with a clear error + retry when the network is unavailable.

## 9. Naming

| Type | Convention | Example |
|------|-----------|---------|
| File | `snake_case` | `trip_repository_impl.dart` |
| Class | `PascalCase` | `TripRepositoryImpl` |
| Bloc | `<Subject>Bloc` | `TripListBloc` |
| Cubit | `<Subject>Cubit` | `TripFilterCubit` |
| Event | `<Verb><Subject>Event` | `LoadTripsEvent` |
| State | `<Subject><Phase>` | `TripLoaded`, `TripError` |
| Use case | `<Verb><Subject>UseCase` | `GetTripsUseCase` |
| Repository impl | `<Subject>RepositoryImpl` | `TripRepositoryImpl` |
| DTO model | `<Subject>Model` | `TripModel` |
| Entity | `<Subject>Entity` | `TripEntity` |
| Variable/fn | `camelCase` | `fetchTrips` |
| Constant | `lowerCamelCase` | `defaultPageSize` |

Features are `snake_case`; plural for collections (`trips`, `vehicles`),
singular for single-resource (`auth`, `profile`).

## 10. Anti-patterns to reject

- Putting a service inside a feature folder — services live in
  `app/services/<function>/`.
- A feature-specific widget in `app/shared/widgets/`.
- `new MyBloc()` / `new MyRepository()` inside a widget instead of `sl<…>()`.
- A `MultiBlocProvider` at the app root eagerly dispatching every fetch at
  startup (couples lifecycle app-wide). Scope blocs to screens; root-scope only
  auth/session.
- Business logic in a widget `build()` or in a datasource.
- Navigating with `context.go` / `context.push` / `Navigator.push` — everything
  goes through `NavigationService` + `AppPages` (see [`navigation.md`](navigation.md)).
- Flutter/Dio/Hive imports inside `domain/`.
- Raw `Map<String,dynamic>` inside an entity or in `Equatable.props`.
- `(x as T)` casts after only a null check — use `safeParse<T>`.
- Catching `Exception` broadly and returning a generic failure (loses the code).
- Storing raw JSON blobs in `SharedPreferences` flat keys with no TTL/eviction.
- Logging request/response bodies.
- Defaulting an unknown or absent permission to "allowed".
