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

Recommended: VS Code or Android Studio with Dart + Flutter plugins.

## 2. Config & flavors

Use Android/iOS flavors (`dev`, `staging`, `prod`) and inject config with `--dart-define-from-file`.

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
```

## 4. Bootstrap order

1. Add stack dependencies in `pubspec.yaml`.
2. Set up config, errors, utils, and DI.
3. Define design tokens and theme.
4. Build network/storage services.
5. Register app dependencies.
6. Create first feature and route.

## 5. Scaffolding a feature

1. Create domain entity + repository contract + use case(s).
2. Implement data layer and model mapping.
3. Build presentation bloc/screens/widgets.
4. Register in `service_locator.dart`.
5. Add route and navigation.
6. Write tests.

## 6. Coding standards

- Use `snake_case` files and `PascalCase` classes.
- Use `final` and `const` whenever possible.
- Keep domain pure and testable.
- Use `safeParse<T>` instead of unsafe runtime casts.

## 7. Linting & formatting

```yaml
include: package:flutter_lints/flutter.yaml
```

Gates: `dart format --set-exit-if-changed .` and `flutter analyze` → 0 issues.

## 8. Dependencies

- Prefer stable, standard packages.
- Pin production versions deliberately.
- Avoid redundant libraries.

## 9. Localization

- Start with `en`.
- Use `intl` and ARB for localized strings and formatting.
- Keep business logic free from user-facing text.
