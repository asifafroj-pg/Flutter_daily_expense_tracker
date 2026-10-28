# Project Structure

The canonical `lib/` layout for a Flutter app. Apply it to the app and to every new feature module.

## Folder tree

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── services/
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── interceptors/
│   │   ├── realtime/realtime_service.dart
│   │   ├── storage/secure_storage.dart
│   │   ├── connectivity/connectivity_service.dart
│   │   ├── notification/notification_service.dart
│   │   ├── formatter/formatter_service.dart
│   │   └── ...
│   ├── core/
│   │   ├── config/app_config.dart
│   │   ├── constants/{app_constants.dart, api_endpoints.dart}
│   │   ├── di/service_locator.dart
│   │   ├── error/{exceptions.dart, failures.dart}
│   │   ├── router/
│   │   │   ├── app_pages.dart
│   │   │   ├── app_router.dart
│   │   │   └── navigation_service.dart
│   │   ├── theme/{app_theme.dart, design_system.dart}
│   │   └── utils/{data_parser.dart, app_logger.dart, validators.dart}
│   └── shared/
│       ├── widgets/
│       └── utils/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── bloc/
│           ├── cubit/
│           ├── screens/
│           └── widgets/
└── assets/
```

## Where to write which file

| Folder | What goes here |
|--------|----------------|
| `app/services/<function>/` | Every service, each in its own functional folder |
| `app/core/` | DI, errors, theme, router, config, utils |
| `app/shared/` | Reusable presentation only |
| `features/<feature>/data/` | Datasources, models, repository impls |
| `features/<feature>/domain/` | Entities, repository contract, use cases |
| `features/<feature>/presentation/bloc/` | Bloc + event + state |
| `features/<feature>/presentation/screens/` | Thin screen composition |
| `features/<feature>/presentation/widgets/` | Feature-specific widgets |
| `main.dart` | Bootstrap only |

## Feature anatomy (example: `items`)

```text
features/items/
├── data/
│   ├── datasources/
│   │   ├── item_remote_data_source.dart
│   │   └── item_local_data_source.dart
│   ├── models/
│   │   └── item_model.dart
│   └── repositories/
│       └── item_repository_impl.dart
├── domain/
│   ├── entities/item_entity.dart
│   ├── repositories/item_repository.dart
│   └── usecases/
│       ├── get_items_usecase.dart
│       └── get_item_detail_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── item_list_bloc.dart
    │   ├── item_list_event.dart
    │   └── item_list_state.dart
    ├── screens/
    │   ├── item_list_screen.dart
    │   └── item_detail_screen.dart
    └── widgets/item_card.dart
```

Then register datasource → repository → use case → bloc in `service_locator.dart`.

## Tests mirror `lib/`

`test/` mirrors `lib/` one-to-one.
