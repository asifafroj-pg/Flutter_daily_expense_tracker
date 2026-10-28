# app_base

A production-ready Flutter application scaffold built to the team's engineering
handbook. It implements Clean Architecture (Presentation → Domain ← Data) with
BLoC/Cubit state management, GetIt dependency injection, go_router navigation,
Dio networking, and dartz `Either<Failure, T>` error handling.

> **Read first:** [`engineering-handbook.md`](engineering-handbook.md) — the
> single source of truth for how this app is built. Then load the doc relevant
> to your task (see the document map there).

## Stack

| Concern | Choice |
|---------|--------|
| State management | `bloc` + `flutter_bloc` (Bloc for event-driven flows, Cubit for simple state) |
| Dependency injection | `get_it` (one container: `lib/app/core/di/service_locator.dart`) |
| Architecture | Clean Architecture, feature-driven (`lib/features/<feature>/`) |
| Error handling | `dartz` `Either<Failure, T>` — raw exceptions never reach the UI |
| Networking | `dio` with auth + logger interceptors (bodies are never logged) |
| Routing | `go_router` wrapped by `AppPages` + `NavigationService` |
| Secure storage | `flutter_secure_storage` for tokens/session |
| Connectivity | `connectivity_plus` via `ConnectivityService` |
| Responsiveness | `flutter_screenutil` (design draft 375 × 812) |
| Equality | `equatable` on every entity/state/event |
| Formatting | `intl` |

## Project layout

```text
lib/
├── main.dart              # bootstrap only
├── app/
│   ├── app.dart           # ScreenUtilInit + MaterialApp.router
│   ├── services/          # network, storage, connectivity, realtime, notification, formatter
│   ├── core/              # config, constants, di, error, router, theme, utils
│   └── shared/widgets/    # AppButton, AppTextField, AsyncView, EmptyState, ErrorView, SmartExit…
└── features/
    ├── auth/              # AuthBloc (app-scoped), login screen, session restore
    ├── splash/            # startup / session-restore gate
    └── items/             # reference CRUD feature (list + detail, pull-to-refresh)
```

`test/` mirrors `lib/` one-to-one.

## Getting started

```bash
flutter pub get
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

Config lives in `config/{dev,staging,prod}.json`. Never commit secrets.

## Quality gates

```bash
dart format --set-exit-if-changed .
flutter analyze        # must be 0 issues
flutter test           # unit + bloc + widget tests
```

Builds:

```bash
flutter build apk --release --flavor prod --dart-define-from-file=config/prod.json \
  --obfuscate --split-debug-info=build/symbols
```

## Conventions highlights

- Blocs/Cubits are `registerFactory`; repositories/use cases/services are
  `registerLazySingleton`; `AuthBloc` is the only app-scoped singleton bloc.
- Every fallible domain/data method returns `Either<Failure, T>`; blocs `fold`.
- All JSON parsing goes through `safeParse<T>` (`app/core/utils/data_parser.dart`).
- Navigation only through `NavigationService` + `AppPages` constants.
- Real-time refresh is the default; offline support is opt-in per feature.
- Screen files ≤ 120 lines; profile every new screen before calling it done.

See [`definition-of-done.md`](definition-of-done.md) before declaring any work complete.
