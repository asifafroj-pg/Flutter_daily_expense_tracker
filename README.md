# Parafleet — Engineering Handbook

> **Parafleet** — the Paragon Vendor Fleet Management mobile app.
> A concern of **Paragon Group**. Backend: the **TMS API**.

This `docs/` folder is the **single source of truth** for how we build this app.
Every engineer and every AI agent working in this repository must read
[`README.md`](README.md) (this file) first, then the doc that matches the task.

---

## For AI agents — start here

1. **Read this file, then [`overview.md`](overview.md).**
2. Load **only** the docs relevant to your task (see the map below). Do not read
   everything — it wastes context.
3. Before writing code, confirm your change against
   [`architecture.md`](architecture.md) + [`bloc-conventions.md`](bloc-conventions.md)
   + [`project-structure.md`](project-structure.md).
4. Run the local gates before declaring done:
   ```bash
   flutter pub get
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   ```
5. **Profile every new/changed screen** in profile mode — hold **90–120 fps**
   (never < 60), with no jank, blink or freeze. Gate:
   [`performance.md`](performance.md).
6. Finish against [`definition-of-done.md`](definition-of-done.md).

### Non-negotiables (memorize these)

- **State management is BLoC** (`bloc` + `flutter_bloc`). Bloc for event-driven
  flows, Cubit for simple value state. Never introduce Riverpod / GetX / Provider.
- **DI is GetIt only.** Controllers/blocs are `registerFactory`; repositories and
  use cases are `registerLazySingleton`. Never construct a bloc/repo with `new`
  inside a widget.
- **Clean Architecture layers:** `Presentation → Domain → Data`. The `domain/`
  layer is **pure Dart** (no Flutter, no Dio, no Hive, no bloc imports).
- **Errors are `Either<Failure, T>`** (dartz). Raw exceptions never reach the UI.
- **Domain entities extend `Equatable`**; parse JSON only through `safeParse<T>`.
- **Real-time first** — screens must reflect live state: push (FCM) +
  polling/streams + pull-to-refresh + optimistic updates with rollback. Assume
  the network is present.
- **Offline support is OPT-IN per feature** — never assume it and never build it
  globally. Read [`offline-optional.md`](offline-optional.md) only when a feature
  is explicitly flagged as offline-capable.
- **Performance is enforced per screen.** After finishing **each** screen, profile
  it in profile mode; if it janks, stutters, blinks, freezes, or drops frames,
  **fix it before moving on**. Hold **90–120 fps** on high-refresh devices and
  **never below 60 fps** — see [`performance.md`](performance.md).
- **Secrets live in secure storage / `--dart-define`** — never in code or logs.
- **Never log request/response bodies.**

---

## Document map

| Doc | Read it when you are… |
|-----|-----------------------|
| [`overview.md`](overview.md) | New to the project; need domain context, glossary, branding, or scope. |
| [`architecture.md`](architecture.md) | Designing anything; unsure how layers, DI, routing or auth fit together. |
| [`coding-style.md`](coding-style.md) | Naming, immutability, `safeParse`, Failures/Exceptions, entities vs models. |
| [`project-structure.md`](project-structure.md) | Deciding **where a file goes** or scaffolding a feature. |
| [`bloc-conventions.md`](bloc-conventions.md) | Writing a Bloc/Cubit, events, states, or wiring UI to state. |
| [`navigation.md`](navigation.md) | Adding/opening a screen or route; routing, back-handling, deep links. |
| [`realtime.md`](realtime.md) | Any feature that shows or mutates fast-changing data (**mandatory read**). |
| [`offline-optional.md`](offline-optional.md) | **Only** when a feature is explicitly flagged offline-capable. |
| [`api-integration.md`](api-integration.md) | Calling the TMS API: Dio, interceptors, error envelope, pagination. |
| [`ui-design.md`](ui-design.md) | Building UI: tokens, theming, components, accessibility. |
| [`performance.md`](performance.md) | Finishing a screen; profiling fps, jank, build time, blink, stalls. |
| [`development.md`](development.md) | Setting up, running, building, or scaffolding (the dev workflow). |
| [`qa.md`](qa.md) | Writing tests, reviewing quality, triaging bugs, cutting a build. |
| [`security.md`](security.md) | Handling tokens, PII, network, release hardening, permissions. |
| [`git-workflow.md`](git-workflow.md) | Branching, commits, PRs, versioning, releases. |
| [`definition-of-done.md`](definition-of-done.md) | Before you say "done" — the acceptance checklist. |

> This handbook was adopted from the `flutter-architecture` skill and then
> specialised for Parafleet (that skill has since been removed). Where the two
> ever differ, **this handbook wins** — we standardised on **BLoC (that skill's
> "Case 4")**, a **vendor-only** audience, and **real-time-first with optional
> offline**.

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

The app is at **greenfield** stage (Flutter counter template + branding already
in place). The docs describe the **target architecture**. When you implement a
feature, bring the surrounding scaffolding up to these docs as you go, and never
leave the tree half-migrated (a mixture of old and new patterns is the worst
state).

See [`development.md`](development.md) → *Bootstrap order* for the exact
sequence to stand the architecture up.
