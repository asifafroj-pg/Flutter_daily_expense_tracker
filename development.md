# Development Workflow

How to set up, run, scaffold and ship Parafleet day-to-day.

## Contents

1. [Prerequisites & tooling](#1-prerequisites--tooling)
2. [Config & flavors](#2-config--flavors)
3. [Commands](#3-commands)
4. [Bootstrap order](#4-bootstrap-order)
5. [Scaffolding a feature](#5-scaffolding-a-feature)
6. [Coding standards](#6-coding-standards)
7. [Linting & formatting](#7-linting--formatting)
8. [Dependencies](#8-dependencies)
9. [Localization](#9-localization)

---

## 1. Prerequisites & tooling

| Tool | Version |
|------|---------|
| Flutter | **3.47.x stable** (project pinned) |
| Dart SDK | `^3.13.5` (from `pubspec.yaml`) |
| Java/JDK | 17 (Android) |
| Android SDK | `compileSdk`/`targetSdk` from Flutter |

Recommended: VS Code or Android Studio with Dart + Flutter plugins, format on
save, and the repo's `analysis_options.yaml`. FVM is optional but pinning the
Flutter version per-repo is encouraged.

## 2. Config & flavors

Use Android/iOS **flavors** (`dev`, `staging`, `prod`) and inject config with
`--dart-define-from-file`. Each flavor gets its own `applicationId`/bundle id
suffix so all three can be installed side by side.

```
config/
├── dev.json        { "APP_ENV":"dev", "API_BASE_URL":"http://localhost:4000", "ENABLE_LOGGING":true }
├── staging.json    { "APP_ENV":"staging", "API_BASE_URL":"…", "ENABLE_LOGGING":true }
└── prod.json       { "APP_ENV":"prod", "API_BASE_URL":"…", "ENABLE_LOGGING":false }
```

- **Never commit secrets.** `config/*.json` holds only non-secret config; tokens
  come from the user at runtime and live in secure storage.
- `AppConfig` (see [`api-integration.md`](api-integration.md) §1) is the only
  place env values are read.

## 3. Commands

```bash
flutter pub get
dart format .                     # format
flutter analyze                   # must be clean (0 issues)
flutter test                      # unit + widget
flutter test --coverage
flutter test integration_test     # E2E (device/emulator)

# Run
flutter run --flavor dev --dart-define-from-file=config/dev.json

# Build
flutter build apk   --release --flavor prod --dart-define-from-file=config/prod.json
flutter build appbundle --release --flavor prod --dart-define-from-file=config/prod.json \
  --obfuscate --split-debug-info=build/symbols
```

## 4. Bootstrap order

Stand the architecture up in this order (each step compiles before the next):

1. **pubspec** — add the Case-4 stack (`bloc`, `flutter_bloc`, `get_it`,
   `go_router`, `dio`, `equatable`, `dartz`, `connectivity_plus`,
   `flutter_secure_storage`, `flutter_screenutil`, `cached_network_image`,
   `shimmer`, `font_awesome_flutter`, `intl`, `logger`; dev: `bloc_test`,
   `mocktail`). See [`security.md`](security.md) for hardening deps.
2. **Core** — `app/core/config/app_config.dart`,
   `constants/{app_constants,api_endpoints}.dart`,
   `error/{exceptions,failures}.dart`, `utils/data_parser.dart`,
   `utils/app_logger.dart`.
3. **Design system** — `theme/design_system.dart`, `theme/app_theme.dart`,
   `theme/theme_cubit.dart`.
4. **Services** — `storage/secure_storage.dart`,
   `connectivity/connectivity_service.dart`,
   `network/dio_client.dart` + interceptors,
   `notification/notification_service.dart`, `realtime/realtime_service.dart`.
   (`cache/` + `sync/` **only if** an offline feature is approved.)
5. **DI** — `core/di/service_locator.dart` with `initializeDependencies()`.
6. **Auth** — entity, repository, use cases, `AuthBloc` (app-scoped).
7. **Routing** — `core/router/app_pages.dart` (route registry),
   `core/router/app_router.dart` (route table + auth `redirect`),
   `core/router/navigation_service.dart` (call `NavigationService.instance.init(router)`),
   then `app/app.dart`. See [`navigation.md`](navigation.md).
8. **main.dart** — bindings → config → `initializeDependencies()` → `runApp`.
9. **First feature** — `auth` (login) then `dashboard`.

## 5. Scaffolding a feature

Copy this recipe for each new feature (example: `trips`):

1. **Domain** — `domain/entities/trip_entity.dart` (`Equatable`),
   `domain/repositories/trip_repository.dart` (abstract),
   `domain/usecases/{get_trips,get_trip_detail,change_trip_status}_usecase.dart`.
   Pure Dart only.
2. **Data** — `data/models/trip_model.dart` (`extends TripEntity`, `fromJson`/
   `toJson` via `safeParse`), `data/datasources/trip_remote_data_source.dart`,
   `data/repositories/trip_repository_impl.dart` (maps exceptions → `Failure`).
3. **Presentation** — `presentation/bloc/{trip_list_bloc,_event,_state}.dart`,
   `presentation/screens/trip_list_screen.dart`,
   `presentation/widgets/trip_card.dart`.
4. **DI** — register datasource → repository → use cases
   (`registerLazySingleton`) and the bloc (`registerFactory`) in
   `service_locator.dart`.
5. **Route** — add the path constant(s) to `app_pages.dart` and the matching
   `GoRoute` to `app_router.dart`. Navigate with
   `NavigationService.navigateTo(AppPages.x)`; guard back with `SmartExit`.
6. **Tests** — mirror under `test/features/trips/…` (see [`qa.md`](qa.md)).
7. **String/arbs + a11y + states** — loading/empty/error, semantic labels.
8. **Gates** — `dart format`, `flutter analyze`, `flutter test` all clean.

Checklist form: [`definition-of-done.md`](definition-of-done.md).

## 6. Coding standards

- **Naming** per [`architecture.md`](architecture.md) §9. Files `snake_case`.
- **Immutability**: `const` wherever possible; `final` fields; `copyWith` for
  changes.
- **Doc comments** `///` on every public API; `//` only for non-obvious detail.
- **Domain purity**: `domain/` imports no Flutter/Dio/Hive/bloc.
- **Parsing**: only via `safeParse<T>`.
- **Trailing commas** in multi-line literals & argument lists.
- **File length**: > ~300 lines is a smell — split it (generated/large bloc files
  excepted).
- **No dead code**: remove unused deps/services; don't ship infrastructure the UI
  never reads.

## 7. Linting & formatting

`analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    public_member_api_docs: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_dynamic_calls: true
    require_trailing_commas: true
    always_declare_return_types: true
```

Formatting is enforced in CI: `dart format --set-exit-if-changed .`. Analyze must
be **0 issues** (not just 0 errors) in CI.

## 8. Dependencies

- Pin exact versions for production; upgrade deliberately with
  `flutter pub upgrade --major-versions` and a green test run.
- Any new dependency requires: (a) it isn't already covered, (b) a maintenance
  check, (c) a security scan (see [`security.md`](security.md) §8).
- Prefer the standard stack; don't introduce a second HTTP client, a second DI
  container, or a second state library.

### Recommended stack (BLoC)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

  # ── Core architecture (BLoC + GetIt) ──
  bloc: ^8.1.3
  flutter_bloc: ^8.1.4
  go_router: ^18.1.0            # already added
  get_it: ^7.6.7
  equatable: ^2.0.5
  dartz: ^0.10.1

  # ── Networking ──
  dio: ^5.4.0
  connectivity_plus: ^5.0.2

  # ── Storage ──
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1

  # ── UI / UX ──
  flutter_screenutil: ^5.9.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  font_awesome_flutter: ^10.7.0

  # ── Utilities ──
  intl: ^0.20.3
  logger: ^2.0.2+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^9.1.5
  mocktail: ^1.0.3
```

> Hive/`hive_flutter`, `uuid` and the `cache`/`sync` services are added **only**
> when a feature is opted into offline ([`offline-optional.md`](offline-optional.md)).
> Pin exact versions for production. `flutter_lints` is already configured.

## 9. Localization

- Target locale(s): `en` first; add `bn` when product asks.
- Strings via `flutter_localizations` + ARB (`l10n.yaml`, `lib/l10n/app_en.arb`).
- **No user-facing strings in Bloc/usecase/datasource layers** — the domain stays
  text-free; screens translate.
- Numbers/currency/dates via `intl` only.
