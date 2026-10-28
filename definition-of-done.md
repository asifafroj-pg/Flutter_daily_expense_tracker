# Definition of Ready / Done

The objective acceptance checklist. If any box is unticked, the work is **not**
done. Agents and humans both run this before declaring completion.

## Definition of Ready (before starting)

- [ ] The requirement is understood and, if ambiguous, confirmed with the owner.
- [ ] The relevant API endpoints are known and match `response.md` (OpenAPI).
- [ ] The screen's **freshness tier** is decided ([`realtime.md`](realtime.md) §1).
- [ ] The screen's **performance target** is known: 90–120 fps, never < 60
      ([`performance.md`](performance.md) §1).
- [ ] Offline requirement is explicit: **off** by default; if on, the feature is
      added to the opt-in register in [`offline-optional.md`](offline-optional.md).
- [ ] Required permissions for the actions are known.
- [ ] Acceptance criteria are written (happy + error + empty paths).

## Definition of Done

### Domain
- [ ] Entities `extend Equatable`, immutable, `props` complete, no raw `Map`.
- [ ] Repository contract is abstract in `domain/`; no Flutter/Dio/Hive imports.
- [ ] One use case per action; returns `Either<Failure, T>`; has unit tests
      (success / business failure / unexpected).

### Data
- [ ] Model `extends` entity with `fromJson`/`toJson` via **`safeParse<T>`**.
- [ ] Parsing tested against recorded fixtures, incl. string-encoded numbers,
      missing and mistyped fields.
- [ ] Repository maps each exception to its **own** `Failure`; no raw exception
      escapes.
- [ ] Error mapping tests cover 400/401/403/404/409/5xx/network.

### Presentation (BLoC)
- [ ] Bloc/Cubit chosen deliberately; files/classes named per
      [`bloc-conventions.md`](bloc-conventions.md).
- [ ] States model Initial/Loading/Loaded/Empty/Error + freshness/busy flags.
- [ ] Every handler **folds** `Either`; no exception reaches the UI.
- [ ] Silent refresh keeps data on screen; no blanking.
- [ ] Optimistic updates (if any) roll back on failure.
- [ ] Bloc registered as **factory**; `AuthBloc` (only) as singleton.
- [ ] Bloc tests cover happy / empty / error / pagination / rollback
      (`bloc_test`).
- [ ] Bloc closes its pollers/timers in `close()`.

### UI
- [ ] All four states implemented (loading skeleton, empty, error+Retry, content).
- [ ] **Screen file ≤ 120 lines**; every visual block extracted into a **public**
      widget under `presentation/widgets/` and composed by the screen
      ([`ui-design.md`](ui-design.md) §9).
- [ ] **No whole-form/screen rebuild**: no `context.watch` in a screen's root
      `build()`, and no `setState` over more than one leaf widget — each widget
      reads only what it displays ([`bloc-conventions.md`](bloc-conventions.md)
      §8).
- [ ] **Every image is size-hinted** (`cacheWidth`/`cacheHeight`) and static
      headers sit behind a `RepaintBoundary`
      ([`performance.md`](performance.md) §5–6).
- [ ] Refresh via pull-to-refresh; last-good data retained during refresh.
- [ ] Values from design tokens; `flutter_screenutil` extensions; no magic numbers.
- [ ] Dark mode + largest system font render without overflow.
- [ ] 44×44 tap targets; `semanticLabel`s on meaningful icons/images.
- [ ] User-facing text lives in the UI layer (translatable), not in bloc/domain.

### Performance (every screen — see [`performance.md`](performance.md))
- [ ] Profiled in **profile/release** mode on a mid-range device (not debug).
- [ ] **90–120 fps** sustained; **never < 60 fps**; zero jank on scroll/transition.
- [ ] No UI or raster frame over budget; screen opens with no build stall.
- [ ] Lists use `.builder`; only needed widgets rebuild; realtime ticks update
      only what changed.
- [ ] No blink/flash on load, refresh, navigate, rotate or theme change.
- [ ] No freeze/ANR; large JSON parsed off the main isolate.
- [ ] Any perf regression found was **fixed and re-profiled** (not deferred).

### Integration & real-time
- [ ] Path constant added to `app_pages.dart` **and** matching `GoRoute` in
      `app_router.dart`; identity via path params, not `extra`. Navigation via
      `NavigationService` + `AppPages` (no `context.go`); home/tab screens
      wrapped in `SmartExit`.
- [ ] Live/near-live screens poll **only while visible**; pause on background,
      refresh on resume.
- [ ] Push (if applicable) mapped to route + refresh, permission-gated.
- [ ] Errors are typed and user-facing (no `e.toString()`); Retry wired.

### Security
- [ ] No secrets committed; nothing sensitive logged (no bodies/tokens/PII).
- [ ] Permission-gated actions hidden when not permitted; server still enforces.
- [ ] No new/unjustified permissions; cleartext disabled in release.

### Quality gates
- [ ] `dart format --set-exit-if-changed .` clean.
- [ ] `flutter analyze` → **0 issues**.
- [ ] `flutter test` green; critical-file coverage floors met.
- [ ] Integration acceptance gate (login → core journey) green.
- [ ] Every new/changed screen passes the performance gate
      ([`performance.md`](performance.md) §9) — 90–120 fps, no jank/blink/freeze.
- [ ] PR includes what/why/how-to-verify + screenshots for UI.
- [ ] `docs/` updated if a pattern or contract changed.

### Release (when cutting a build)
- [ ] Version + build number bumped; `CHANGELOG.md` updated.
- [ ] Prod flavor built with `--obfuscate --split-debug-info`; symbols archived.
- [ ] `API_BASE_URL` verified = prod; cleartext off; R8/minify on.
- [ ] Smoke test on a real device; tag `v<version>` on `main`.

---

## Fast path (small fixes)

For a trivial, low-risk fix, the same spirit applies but you may collapse the
list to: **correctness + a regression test + format/analyze/test green + a note
in the PR**. When in doubt, run the full list.
