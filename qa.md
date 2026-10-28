# Quality Assurance & Testing

Test shape follows the code, not a fixed pyramid. Push logic down into testable
layers, then test each layer at its natural level.

## Contents

1. [Test strategy](#1-test-strategy)
2. [Domain & data tests](#2-domain--data-tests)
3. [Bloc tests](#3-bloc-tests)
4. [Widget & golden tests](#4-widget--golden-tests)
5. [Integration / acceptance gate](#5-integration--acceptance-gate)
6. [Fakes vs mocks](#6-fakes-vs-mocks)
7. [Test data & fixtures](#7-test-data--fixtures)
8. [Coverage policy](#8-coverage-policy)
9. [CI gates](#9-ci-gates)
10. [Manual QA checklist](#10-manual-qa-checklist)
11. [Bug severity & triage](#11-bug-severity--triage)
12. [Performance & frame-time testing](#12-performance--frame-time-testing)

---

## 1. Test strategy

| Layer | Test type | Tools |
|-------|-----------|-------|
| Domain (entities, use cases) | Pure unit | `test`, `dartz` assertions |
| Data (models, repos, datasources) | Unit with fakes + real storage engines | `test`, `mocktail`, real `SharedPreferences`/secure storage |
| Presentation (Bloc/Cubit) | State-machine unit | `bloc_test` |
| Presentation (widgets/screens) | Widget | `flutter_test` |
| Design system & critical UI | Golden | `flutter_test` golden |
| Cross-feature journeys | Integration (E2E) | `integration_test` on device |

`test/` mirrors `lib/` one-to-one. **Write tests alongside the code** (TDD where
practical — bloc tests are ideal for it).

## 2. Domain & data tests

- **Use cases**: assert `Left(failure)` / `Right(value)` for the three paths —
  success, business failure, unexpected error. Inject a fake repository.
- **Repository**: the real logic under test is the **error mapping** and the
  **fallback order**. Inject fake datasources and assert:
  - remote success → `Right` (+ cache written if opted in),
  - `ServerException` → `Left(ServerFailure)`,
  - network error → cache fallback or `Left(NetworkFailure)`,
  - 4xx codes → the matching typed `Failure`.
- **Models**: golden-test `fromJson` against **recorded real API responses**
  (copy payloads into `test/fixtures/`). Assert string-encoded numbers
  (`"rate":"12000"`), missing fields, and mistyped fields all parse via
  `safeParse` instead of throwing.
- Test datasources against **real** `SharedPreferences`/`FlutterSecureStorage`
  test doubles, not hand-rolled mocks of them.

## 3. Bloc tests

`bloc_test` is the backbone. Every bloc gets tests for each event's happy path,
empty, error, and rollback paths.

```dart
blocTest<TripListBloc, TripListState>(
  'offline error keeps the last loaded list and surfaces a message',
  build: () { /* fakes returning Right then Left */ },
  seed: () => TripListLoaded(trips: [tTrip], page: 1, hasMore: false),
  act: (b) => b.add(const TripListRefreshed(silent: true)),
  expect: () => [
    isA<TripListLoaded>().having((s) => s.isRefreshing, 'isRefreshing', true),
    isA<TripListLoaded>()
        .having((s) => s.trips, 'keeps data', hasLength(1))
        .having((s) => s.error, 'error', isNotNull),
  ],
);
```

Cover: `Loading→Loaded`, `Loading→Empty`, `Loading→Error`, pagination append,
optimistic update + **rollback**, and (if opted in) offline replay. Use
`fake_async` for pollers — never real `Future.delayed`.

## 4. Widget & golden tests

- Widget-test screens with a **fake bloc** (or `BlocProvider` + fake use case):
  assert loading skeleton, empty state, error + retry, and loaded list render.
- Assert **user actions** dispatch the right event (`context.read<...>().add`).
- **Golden tests** for the design system: `AppButton`, `AppCard`, `EmptyState`,
  `ErrorView`, and any pixel-critical custom widget. Run with `--update-goldens`
  intentionally and review diffs in PRs.

## 5. Integration / acceptance gate

Keep **one** end-to-end journey green on a device/emulator as the release gate,
plus focused integration tests for the riskiest flows:

- **Login → dashboard → open a trip → change status → verify** (the gate).
- Token expiry → 401 → redirect to login.
- Push payload → deep link opens the right (permission-gated) screen.

`integration_test/` runs in CI on an Android emulator.

## 6. Fakes vs mocks

- **Code we own** (repositories, use cases, services): prefer a **hand-written
  fake** implementing the interface — clearer, no codegen, asserts state not
  call order.
- **External collaborators** (Dio, plugin channels): `mocktail` fakes/mocks.
- Never assert on private internals; assert on **observable behaviour** (emitted
  states, returned `Either`, rendered widgets).

## 7. Test data & fixtures

- One `test/fixtures/` with recorded JSON payloads (trimmed of PII).
- Builders for entities (`aTrip()`, `aVehicle()`) with sane defaults + overrides
  — avoids brittle giant literals and makes intent obvious.
- Keep timestamps fixed (inject a `Clock`) so goldens and assertions are stable.

## 8. Coverage policy

- No vanity global % target. **Floor coverage on high-risk files**:
  error mapping, auth/session, money/quantity maths, cache/TTL (if opted in),
  permission gating. These must be **~100%**.
- Screens/complex UI rely on widget + a few goldens, not line coverage.
- Enable `--coverage`; surface the report in CI; fail only on the critical-file
  floors, not the aggregate.

## 9. CI gates

Every PR must pass (in order):

1. `dart format --set-exit-if-changed .`
2. `flutter analyze` — **0 issues**.
3. `flutter test` (+ coverage).
4. `flutter test integration_test` (device/emulator job).
5. Dependency/security scan (see [`security.md`](security.md) §8).

No merge with a red gate. Flaky test ⇒ fix or quarantine with an issue; never
retry-to-green silently.

## 10. Manual QA checklist

Per feature, on a real device:

- [ ] Fresh install → login → every screen renders (loading/empty/error/content).
- [ ] **Airplane mode**: every screen fails fast with a clear message + Retry
      (or serves cached data **only** if the feature is offline-opted-in).
- [ ] Slow network (throttled): skeletons show, no blank screens, no ANR.
- [ ] Rotation / tablet width: layout reflows, no overflow.
- [ ] Largest system font: no clipped text.
- [ ] Dark mode: contrast and tokens hold.
- [ ] Back navigation & deep link (from a push) land correctly; guarded screens
      respect permissions.
- [ ] Token expiry mid-session → clean redirect to login; no data leak.
- [ ] Money/quantity/date formatting correct (`BDT`, units, UTC→local).
- [ ] TalkBack/VoiceOver labels read sensibly.
- [ ] **Performance gate passed** for every new/changed screen — profile mode,
      90–120 fps, no jank/blink/freeze ([`performance.md`](performance.md) §9).

## 11. Bug severity & triage

| Sev | Definition | Response |
|-----|------------|----------|
| **S1** | Data loss, wrong money, auth bypass, crash on launch | Hotfix; stop other work |
| **S2** | Feature broken, no workaround | Fix in current cycle |
| **S3** | Degraded UX with workaround | Schedule next cycle |
| **S4** | Cosmetic | Backlog |

Triage: reproduce → capture `requestId` + endpoint from logs → classify → add a
**regression test** with the fix. Never fix a bug without a test that would have
caught it.

## 12. Performance & frame-time testing

Performance is verified **per screen**, not per release. Full spec:
[`performance.md`](performance.md).

- **Profile mode only** — `flutter run --profile`. Never judge fps in debug.
- **Assert frames in the acceptance gate.** In `integration_test`, drive a scroll
  / transition and collect frame timings (`traceAction` / `watchPerformance`);
  fail the gate on jank or over-budget frames.
- **Per-PR evidence** — capture the DevTools frame chart for new/changed screens
  and paste the summary ([`performance.md`](performance.md) §10) into the PR.
- **Regression = bug.** A jank, blink, stall or fps drop found the first time a
  screen runs is fixed *before* the screen is considered done — log it as an S2/S3
  ([§11](#11-bug-severity--triage)) with a note of the fix, or S1 if it freezes
  the app.
- **Reference device** — test on a mid-range phone, not only the fastest one; a
  screen that only holds 90–120 fps on flagship hardware has not passed.
- **Watch for**: rebuild storms, raster spikes (blur/clip/opacity), full-list
  builds, main-isolate JSON parsing, image decode bloat, and placeholder flashes.

Tie-in with the [CI gates](#9-ci-gates): format → analyze → tests → integration
(now including the frame-time assertions) → security scan.
