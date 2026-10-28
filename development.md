# Development Workflow

How to set up, run, scaffold, and ship a Flutter app day to day.

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
| Flutter | Stable channel |
| Dart SDK | Compatible with project `pubspec.yaml` |
| Java/JDK | 17 for Android |
| Android SDK | Per Flutter environment |

Recommended: VS Code or Android Studio with Dart + Flutter plugins, format on save, and the repo's `analysis_options.yaml`.

## 2. Config & flavors

Use Android/iOS flavors (`dev`, `staging`, `prod`) and inject config with `--dart-define-from-file`.

```bash
config/
├── dev.json
├── staging.json
└── prod.json
```

- Never commit secrets.
- Keep only non-secret config in these files.
- Read env values in a single `AppConfig` abstraction.

## 3. Commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter test --coverage

# Run
flutter run --flavor dev --dart-define-from-file=config/dev.json

# Build
flutter build apk --release --flavor prod --dart-define-from-file=config/prod.json
flutter build appbundle --release --flavor prod --dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols
```

## 4. Bootstrap order

1. **pubspec** — add the architecture stack.
2. **Core** — config, constants, errors, utils, DI.
3. **Design system** — theme tokens + app theme.
4. **Services** — storage, connectivity, networking, notifications.
5. **DI** — `service_locator.dart` with `initializeDependencies()`.
6. **Auth** — entity, repository, use cases, `AuthBloc`.
7. **Routing** — `app_pages.dart`, `app_router.dart`, `navigation_service.dart`.
8. **main.dart** — bootstrap, DI, `runApp`.
9. **First feature** — auth, dashboard, then the next feature.

## 5. Scaffolding a feature

Copy this recipe for each new feature:

1. **Domain** — entity, repository, use case(s)
2. **Data** — models, datasources, repository impl
3. **Presentation** — bloc, screens, widgets
4. **DI** — register datasource → repository → use case → bloc
5. **Route** — add path constant(s), matching `GoRoute`, navigate via `NavigationService`
6. **Tests** — write domain, data, bloc, and widget tests
7. **String / ARB + a11y + states** — loading / empty / error / content
8. **Gates** — format, analyze, test all clean

## 6. Coding standards

- Naming per architecture document
- Immutability: `const` wherever possible; `final` fields
- Domain code stays pure Dart
- Use `safeParse<T>` for all JSON conversion
- Keep file length sane; split large files
- Remove dead code

## 7. Linting & formatting

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

Formatting is enforced in CI. Analyze must be 0 issues.

## 8. Dependencies

- Pin exact versions for production.
- Prefer the standard stack; avoid introducing multiple network clients or state libraries.
- Any new dependency requires a justification and a quick maintenance check.

## 9. Localization

- Start with English; add other languages only when required.
- Use localized strings in the UI layer, not in domain or data.
- Format numbers, dates, and currency using `intl`.
