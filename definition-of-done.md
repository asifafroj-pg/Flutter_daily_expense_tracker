# Definition of Ready / Done

The objective acceptance checklist. If any box is unticked, the work is not done.

## Definition of Ready (before starting)

- [ ] The requirement is understood and, if ambiguous, confirmed with the owner.
- [ ] The API contract is known and matches backend contracts / OpenAPI.
- [ ] The screen's freshness tier is decided.
- [ ] The screen's performance target is known.
- [ ] Offline requirement is explicit: off by default; if on, the feature is added to the opt-in register.
- [ ] Required permissions for the actions are known.
- [ ] Acceptance criteria are written (happy + error + empty paths).

## Definition of Done

### Domain
- [ ] Entities extend `Equatable`, immutable, `props` complete, no raw `Map`.
- [ ] Repository contract is abstract in `domain/`; no Flutter/Dio/Hive imports.
- [ ] One use case per action; returns `Either<Failure, T>` and has unit tests.

### Data
- [ ] Model extends entity with `fromJson` / `toJson` via `safeParse<T>`.
- [ ] Parsing tested against known fixtures.
- [ ] Repository maps each exception to its own `Failure`; no raw exception escapes.
- [ ] Error mapping tests cover the important statuses.

### Presentation (BLoC)
- [ ] Bloc/Cubit chosen deliberately and named per convention.
- [ ] States model proper phases with freshness/busy flags.
- [ ] Every handler folds `Either`; no exception reaches the UI.
- [ ] Silent refresh keeps data on screen.
- [ ] Optimistic updates rollback on failure.
- [ ] Bloc registered as a factory; `AuthBloc` only as singleton.
- [ ] Bloc tests cover happy / empty / error / rollback paths.
- [ ] Bloc closes pollers/timers in `close()`.

### UI
- [ ] All four states implemented (loading, empty, error + Retry, content).
- [ ] Screen file ≤ 120 lines; abstractions live in widget files.
- [ ] No whole-form/screen rebuild; no `setState` over more than one leaf widget.
- [ ] Images are size-hinted and static headers sit behind `RepaintBoundary` when needed.
- [ ] Refresh via pull-to-refresh where appropriate.
- [ ] Values from design tokens; no magic numbers.
- [ ] Dark mode + largest font render without overflow.
- [ ] 44×44 tap targets; `semanticLabel`s on meaningful icons/images.

### Performance
- [ ] Profiled in profile/release mode on a representative device.
- [ ] 90–120 fps sustained; never below 60 fps.
- [ ] No jank on scroll or transitions.
- [ ] Lists use `.builder` and only needed widgets rebuild.
- [ ] No blink/flash on load, refresh, navigate, rotate or theme change.

### Integration & real-time
- [ ] Path constant added to `app_pages.dart` and matching `GoRoute` in `app_router.dart`.
- [ ] Navigation via `NavigationService` + `AppPages`.
- [ ] Live/near-live screens poll only while visible.
- [ ] Push events are mapped to route + refresh when applicable.
- [ ] Errors are typed and user-facing.

### Security
- [ ] No secrets committed; nothing sensitive logged.
- [ ] Permission-gated actions hidden when not allowed; backend still enforces.
- [ ] No new/unjustified permissions; cleartext disabled in release.

### Quality gates
- [ ] `dart format --set-exit-if-changed .` clean.
- [ ] `flutter analyze` → **0 issues**.
- [ ] `flutter test` green.
- [ ] Integration acceptance gate green.
- [ ] New/changed screens pass performance gate.
- [ ] Docs updated if a pattern or contract changed.

### Release (when cutting a build)
- [ ] Version + build number bumped; changelog updated.
- [ ] Prod flavor built with obfuscation + symbol files.
- [ ] `API_BASE_URL` verified; cleartext off; signing correct.

---

## Fast path (small fixes)

For a trivial, low-risk fix, collapse the list to: correctness + regression test + format/analyze/test green + a note in the PR.
