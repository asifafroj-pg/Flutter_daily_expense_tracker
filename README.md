# Project Engineering Handbook

> This repository follows a simple, scalable Flutter architecture that works for most product teams and can be adapted to any app.

This handbook is the single source of truth for how we build the app. Every engineer and AI agent working in this repository should read this file first, then the relevant doc for the task.

---

## For AI agents — start here

1. Read this file, then [`overview.md`](overview.md).
2. Load only the docs relevant to the task.
3. Before writing code, confirm your change against [`architecture.md`](architecture.md), [`bloc-conventions.md`](bloc-conventions.md), and [`project-structure.md`](project-structure.md).
4. Run the local gates before declaring done:
   ```bash
   flutter pub get
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   ```
5. Profile every new or changed screen in profile mode for smooth performance.
6. Finish against [`definition-of-done.md`](definition-of-done.md).

### Non-negotiables

- State management is BLoC (`bloc` + `flutter_bloc`). Bloc for event-driven flows, Cubit for simple value state. Do not introduce a second state library.
- DI is GetIt only. Controllers and blocs are `registerFactory`; repositories and use cases are `registerLazySingleton`.
- Use Clean Architecture layers: Presentation → Domain → Data.
- Errors are `Either<Failure, T>` (dartz). Raw exceptions never reach the UI.
- Domain entities extend `Equatable`; parse JSON only through a shared `safeParse` helper.
- Real-time refresh is default; offline support is opt-in, not a global assumption.
- Performance is a requirement: profile each screen and fix jank before finishing.
- Secrets live in secure storage or environment configuration, never in code.
- Never log request or response bodies.

---

## Document map

| Doc | Read it when you are… |
|-----|-----------------------|
| [`overview.md`](overview.md) | Getting oriented or onboarding to the app. |
| [`architecture.md`](architecture.md) | Designing anything; unsure how layers, DI, routing or auth fit together. |
| [`coding-style.md`](coding-style.md) | Writing code and following naming / hygiene rules. |
| [`project-structure.md`](project-structure.md) | Deciding where a file should live or scaffolding a feature. |
| [`bloc-conventions.md`](bloc-conventions.md) | Writing a Bloc/Cubit, events, states, or wiring UI to state. |
| [`navigation.md`](navigation.md) | Adding or opening a screen; routing, back handling, deep links. |
| [`realtime.md`](realtime.md) | Any feature with live or refresh-driven data. |
| [`offline-optional.md`](offline-optional.md) | Only when a feature is explicitly offline-capable. |
| [`api-integration.md`](api-integration.md) | Working with the backend: Dio, interceptors, error envelope, pagination. |
| [`ui-design.md`](ui-design.md) | Building UI: tokens, theming, components, accessibility. |
| [`performance.md`](performance.md) | Finishing a screen; profiling jank, build time, blink, stalls. |
| [`development.md`](development.md) | Setting up, running, building, or scaffolding. |
| [`qa.md`](qa.md) | Writing tests, reviewing quality, triaging bugs, cutting a build. |
| [`security.md`](security.md) | Handling tokens, data protection, network, release hardening. |
| [`git-workflow.md`](git-workflow.md) | Branching, commits, PRs, versioning, releases. |
| [`definition-of-done.md`](definition-of-done.md) | Before you say “done” — the acceptance checklist. |

---

## Quick commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Run (dev) | `flutter run --flavor dev --dart-define-from-file=config/dev.json` |
| Profile (measure fps) | `flutter run --profile --flavor dev --dart-define-from-file=config/dev.json` |
| Format | `dart format .` |
| Lint/analyze | `flutter analyze` |
| Unit + widget tests | `flutter test` |
| Coverage | `flutter test --coverage` |
| Integration tests | `flutter test integration_test` |
| Build APK (release) | `flutter build apk --release --flavor prod --dart-define-from-file=config/prod.json` |

---

## Status of this repository

This project is intended to be a clean, reusable Flutter base for product work. The docs describe the target architecture and conventions. When implementing a feature, bring the surrounding scaffolding up to these standards as you go and avoid leaving the tree half-migrated.

See [`development.md`](development.md) → Bootstrap order for the exact setup sequence.
