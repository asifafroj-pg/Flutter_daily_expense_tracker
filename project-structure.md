# Project Structure

The canonical `lib/` layout for Parafleet. Apply it to the app and to **every**
new feature module. (This is the reference skill's Case 2/3/4 shape; we use the
BLoC delta for presentation.)

## Folder tree

```
lib/
├── main.dart                    # Bootstrap ONLY: bindings, config, DI, runApp(ProviderScope-free)
├── app/
│   ├── app.dart                 # Root widget: MaterialApp.router, theme, ScreenUtilInit
│   ├── services/                # ★ ALL services — one functional folder each
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── interceptors/{auth,logger,error}_interceptor.dart
│   │   ├── realtime/realtime_service.dart   # polling / streams / push routing
│   │   ├── storage/secure_storage.dart
│   │   ├── connectivity/connectivity_service.dart
│   │   ├── notification/notification_service.dart
│   │   ├── formatter/formatter_service.dart
│   │   ├── cache/cache_service.dart         # OPTIONAL — offline-optional.md
│   │   ├── sync/offline_queue.dart          # OPTIONAL — offline-optional.md
│   │   └── ...
│   ├── core/                    # ★ NON-service cross-cutting infrastructure
│   │   ├── config/app_config.dart
│   │   ├── constants/{app_constants.dart,api_endpoints.dart}
│   │   ├── di/service_locator.dart          # ★ THE only place deps are registered
│   │   ├── error/{exceptions.dart,failures.dart}
│   │   ├── router/
│   │   │   ├── app_pages.dart            # ★ every route path (constants + builders)
│   │   │   ├── app_router.dart           # GoRouter table + auth redirect
│   │   │   └── navigation_service.dart   # ★ singleton navigate wrapper
│   │   ├── theme/{app_theme.dart,design_system.dart,theme_cubit.dart}
│   │   └── utils/{data_parser.dart,app_logger.dart,validators.dart}
│   └── shared/                  # ★ REUSABLE PRESENTATION — feature-agnostic
│       ├── widgets/             # app_scaffold, app_button, app_text_field,
│       │                        # app_network_image, async_view, empty_state,
│       │                        # error_view, offline_banner, smart_exit
│       └── utils/
├── features/                    # ★ FEATURE MODULES — all product behaviour
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/     # abstract + impl: remote (Dio) & local (cache)
│       │   ├── models/          # DTO extends entity; fromJson/toJson via safeParse
│       │   └── repositories/    # <feature>_repository_impl.dart
│       ├── domain/              # 🔒 pure Dart only
│       │   ├── entities/        # extends Equatable
│       │   ├── repositories/    # abstract contract
│       │   └── usecases/        # one class per action; Either<Failure,T>
│       └── presentation/
│           ├── bloc/            # <name>_bloc.dart + _event.dart + _state.dart
│           ├── cubit/           # simple value state (optional)
│           ├── screens/
│           └── widgets/
└── assets/                      # declared in pubspec.yaml
```

## Where to write which file

| Folder | What goes here |
|--------|----------------|
| `app/services/<function>/` | ★ Every service, each in its own functional folder. Singletons; may depend on other services; **never on features**. Add a folder per concern — never pile services flat. |
| `app/core/` | Non-service infrastructure: DI, errors, theme, router, config, utils. **No screens, no services.** |
| `app/shared/` | Generic reusable **presentation** (buttons, inputs, shell, image, empty/error views). **No feature-specific widgets.** |
| `features/<name>/data/` | The **only** layer allowed to import Dio/Hive/services. Datasources, models, repository impls. |
| `features/<name>/domain/` | Entities (`Equatable`), abstract repository contract, use cases (`Either`). Pure Dart. |
| `features/<name>/presentation/bloc/` | Bloc + Event + State triples. |
| `features/<name>/presentation/cubit/` | `Cubit<State>` for simple value/sequence state. |
| `features/<name>/presentation/screens/` | The feature's pages (`BlocProvider` + `BlocBuilder`/`BlocConsumer`). **≤ 120 lines** — a thin composition of the feature's widgets. |
| `features/<name>/presentation/widgets/` | **Public** widgets (header, form, row, footer…) the screen composes. Used only by this feature. |
| `main.dart` | Bootstrap only — no business logic. |

## Feature anatomy (example: `trips`)

```
features/trips/
├── data/
│   ├── datasources/
│   │   ├── trip_remote_data_source.dart     # abstract + impl
│   │   └── trip_local_data_source.dart      # abstract + impl (cache)
│   ├── models/
│   │   └── trip_model.dart                   # extends TripEntity, fromJson/toJson
│   └── repositories/
│       └── trip_repository_impl.dart         # implements TripRepository
├── domain/
│   ├── entities/trip_entity.dart
│   ├── repositories/trip_repository.dart
│   └── usecases/
│       ├── get_trips_usecase.dart
│       ├── get_trip_detail_usecase.dart
│       └── update_trip_status_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── trip_list_bloc.dart
    │   ├── trip_list_event.dart
    │   └── trip_list_state.dart
    ├── cubit/trip_filter_cubit.dart
    ├── screens/{trip_list_screen.dart,trip_detail_screen.dart}
    └── widgets/trip_card.dart
```

Then register datasource → repository → use case → bloc in
`app/core/di/service_locator.dart` (see [`architecture.md`](architecture.md) §4).

## Feature list (planned modules)

Derived from the TMS API surface (see `response.md`). Build in this order.

| Feature folder | Scope |
|----------------|-------|
| `auth` | Login, session restore, logout, password reset |
| `profile` | Vendor profile, current user, settings |
| `dashboard` | Vendor landing summary |
| `notifications` | Inbox + push |
| `vehicles` | Vehicle list/detail, documents, BRTA data |
| `drivers` | Driver list/detail, documents, types |
| `documents` | Compliance docs & expiry |
| `tenders` | Tenders, requirements, quotations (vendor: tenders & quotations) |
| `rates` | Agreed rates |
| `assignments` | Vendor assignments |
| `trips` | Trips, delivery, gate/weighbridge (vendor-facing) |
| `bills` | Vendor bills |
| `claims` | Vendor claims |
| `performance` | Vendor performance metrics |
| `users_roles` | Vendor users & roles (account admin) |

> Name folders after the **domain**, not the screen. A feature that grows too
> large gets **split** (e.g. `documents` split from `vehicles`), never merged.

## Tests mirror `lib/`

`test/` mirrors `lib/` one-to-one. See [`qa.md`](qa.md).

```
test/
└── features/trips/
    ├── domain/usecases/get_trips_usecase_test.dart
    ├── data/repositories/trip_repository_impl_test.dart
    └── presentation/bloc/trip_list_bloc_test.dart
```
