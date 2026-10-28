# Architecture

**Status: decision (locked).** State management is **BLoC / Cubit**. This is the reference pattern for a modern Flutter app: event-driven UI, testable business logic, and clean layering.

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

1. **Clean Architecture** — strict **Presentation / Domain / Data** separation. Domain is pure Dart.
2. **Feature-driven** — code lives in self-contained modules under `lib/features/<feature>/`; a feature never reaches into another feature's internals.
3. **Dependency rule** — dependencies point **inwards only**:
   `Presentation → Domain ← Data`.
4. **Single responsibility** — one class, one job. If you need two sentences to describe it, split it.

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
| **Presentation** | Domain, `flutter_bloc`, `app/shared`, `app/core/theme`, `go_router` | Dio, Hive, datasources, service implementations |
| **Domain** | `dart:core`, `equatable`, `dartz` | Flutter, Dio, Hive, bloc, get_it, anything else |
| **Data** | Domain, Dio, Hive, secure storage, cache service | Presentation |

A cycle means the design is wrong — refactor.

**Data flow for a read:**
`Screen → Bloc.add(Event) → UseCase.call() → Repository → (Remote|Local)DataSource
→ Either<Failure, Entity> → Bloc emits state → BlocBuilder renders`.

**Data flow for a write:**
`Screen → Bloc.add(Event) → UseCase → Repository → RemoteDataSource
→ on success: invalidate cache + refresh; on offline: enqueue for replay`.

Full folder layout: [`project-structure.md`](project-structure.md).

## 3. Why BLoC (the decision record)

- **Explicit, testable state machines.** Every transition is an event + a state.
- **`bloc_test`** gives us strong TDD story.
- **Separation of intent (event) from result (state)** keeps async UI predictable.

Alternatives considered and rejected: GetX (too implicit), Provider-only patterns (harder to scale), multiple competing state libs. One approach helps keep the codebase consistent.

**Bloc vs Cubit — choose deliberately, don't default to Bloc:**

| Use | When |
|-----|------|
| **Bloc** | Event-driven flows, multiple typed events, complex transitions, pagination |
| **Cubit** | Simple value/serial state: a nav index, a filter form, a theme toggle |

Never force events where a plain `emit` from a method is enough.

## 4. Dependency injection — GetIt

`get_it` is the **only** DI mechanism. One container: `lib/app/core/di/service_locator.dart`.

- **Services** → `registerLazySingleton`.
- **Data sources, repositories, use cases** → `registerLazySingleton`.
- **Blocs / Cubits** → `registerFactory`.
- **App-scoped auth/session bloc** → `registerLazySingleton`.

Resolve with `sl<MyBloc>()`, `sl<GetItemsUseCase>()`, etc. Never construct a dependency with `new` inside a widget.

```dart
final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerLazySingleton<SecureStorage>(() => SecureStorageImpl());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityServiceImpl());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl(), sl()));

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<RestoreSessionUseCase>(() => RestoreSessionUseCase(sl()));
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(login: sl(), restore: sl()));

  sl.registerLazySingleton<ItemRepository>(() => ItemRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<GetItemsUseCase>(() => GetItemsUseCase(sl()));
  sl.registerFactory<ItemListBloc>(() => ItemListBloc(getItems: sl()));
}
```

## 5. Error handling — dartz Either

Every domain/data method that can fail returns **`Either<Failure, T>`**.
Exceptions are an internal Data-layer detail; the UI never sees a raw exception.

- `app/core/error/exceptions.dart` — `ServerException`, `NetworkException`, `CacheException`, `AuthException`, `ValidationException`.
- `app/core/error/failures.dart` — abstract `Failure` + concrete failures such as `ServerFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`.

**Each layer maps its own exception to its own Failure** — never mix.

```dart
try {
  final raw = await _remote.getItems();
  return Right(raw.map(ItemModel.fromJson).map((m) => m.toEntity()).toList());
} on ServerException catch (e) {
  return Left(ServerFailure(e.message, statusCode: e.statusCode));
} on NetworkException {
  return const Left(NetworkFailure());
}
```

Blocs `fold` the result: `Left → emit(ErrorState)`, `Right → emit(LoadedState)`.

## 6. Routing — AppPages + NavigationService

go_router is the engine, but it is **wrapped** so routing is centralised and never scattered through widgets:

- **`AppPages`** — every route path as a `static const` or `static String` builder.
- **`NavigationService`** — the singleton wrapper: `navigateTo`, `navigateToReplacement`, `navigateToUntilReplacement`, `goBack`, `canGoBack`.
- **`SmartExit`** — the central `PopScope` back guard.
- **The route table + auth `redirect`** live in `core/router/app_router.dart`.

```dart
NavigationService.navigateTo(AppPages.itemDetail(item.id));
NavigationService.navigateToUntilReplacement(AppPages.login);
```

Full spec: [`navigation.md`](navigation.md).

## 7. Auth, session & roles

Authentication should be centralized and server-driven. The app can show/hide actions based on permissions, but the backend remains the source of truth.

- The token and user profile live in `FlutterSecureStorage` or equivalent secure storage.
- Restore session only by validating with the server; never fabricate a user.
- `AuthBloc` is app-scoped and lives for the lifetime of the app.
- The auth interceptor injects `Authorization` and handles `401` by clearing state and redirecting to login.
- Permission checks are cosmetic in the UI and enforced on the server.

## 8. Real-time & data freshness

Modern apps often need live data. Assume connectivity is available and design screens to refresh and re-render when needed.

- **Push (FCM)** can trigger a route and a refresh.
- **Polling / streams** keep active screens current.
- **Pull-to-refresh** should be available for lists and dashboards.
- **Optimistic updates with rollback** are allowed for safe, reversible mutations.

**Offline support is opt-in.** Only features deliberately marked offline-capable should implement caching and queued writes. Everything else should fail fast with a typed error + retry.

## 9. Naming

| Type | Convention | Example |
|------|-----------|---------|
| File | `snake_case` | `item_repository_impl.dart` |
| Class | `PascalCase` | `ItemRepositoryImpl` |
| Bloc | `<Subject>Bloc` | `ItemListBloc` |
| Cubit | `<Subject>Cubit` | `FilterCubit` |
| Event | `<Verb><Subject>Event` | `LoadItemsEvent` |
| State | `<Subject><Phase>` | `ItemLoaded`, `ItemError` |
| Use case | `<Verb><Subject>UseCase` | `GetItemsUseCase` |
| Repository impl | `<Subject>RepositoryImpl` | `ItemRepositoryImpl` |
| DTO model | `<Subject>Model` | `ItemModel` |
| Entity | `<Subject>Entity` | `ItemEntity` |
| Variable/fn | `camelCase` | `fetchItems` |
| Constant | `lowerCamelCase` | `defaultPageSize` |

Features are `snake_case` and grouped under `lib/features/<feature>/`.

## 10. Anti-patterns to reject

- Putting a service inside a feature folder — services live in `app/services/<function>/`.
- A feature-specific widget in `app/shared/widgets/`.
- `new MyBloc()` inside widgets instead of `sl<…>()`.
- `context.go` / `context.push` / `Navigator.push` for app pages — everything goes through `NavigationService` + `AppPages`.
- Flutter/Dio/Hive imports inside `domain/`.
- Raw `Map<String, dynamic>` in entity props.
- `(x as T)` casts without safe parsing.
- Catching broad exceptions and swallowing them.
- Logging request/response bodies.
- Defaulting unknown permissions to “allowed”.
