# Quality Assurance & Testing

Test shape follows the code, not a fixed pyramid. Push logic down into testable layers, then test each layer at its natural level.

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

---

## 1. Test strategy

| Layer | Test type | Tools |
|-------|-----------|-------|
| Domain | Pure unit | `test` |
| Data | Unit with fakes | `test`, `mocktail` |
| Presentation (Bloc/Cubit) | State-machine unit | `bloc_test` |
| Presentation (widgets/screens) | Widget | `flutter_test` |
| Design system | Golden | `flutter_test` golden |
| Cross-feature journeys | Integration | `integration_test` |

`test/` mirrors `lib/` one-to-one.

## 2. Domain & data tests

- Use cases: assert `Left(failure)` / `Right(value)` for success, business failure, and unexpected error.
- Repository: test error mapping and fallback order.
- Models: verify `fromJson`/`toJson` with realistic fixtures.

## 3. Bloc tests

Use `bloc_test`. Cover happy path, empty, error, and rollback.

```dart
blocTest<ItemListBloc, ItemListState>(
  'emits [Loading, Loaded] when GetItemsUseCase succeeds',
  build: () {
    when(() => getItems.call(page: 1)).thenAnswer((_) async => Right([item]));
    return ItemListBloc(getItems: getItems);
  },
  act: (b) => b.add(const ItemListStarted()),
  expect: () => [
    const ItemListLoading(),
    isA<ItemListLoaded>().having((s) => s.items, 'items', hasLength(1)),
  ],
);
```

## 4. Widget & golden tests

- Widget-test screens with a fake bloc.
- Assert loading skeleton, empty state, error + retry, and loaded list render.
- Golden tests for critical UI pieces like buttons, cards, and empty/error views.

## 5. Integration / acceptance gate

Keep one end-to-end journey green as the release gate, plus targeted integration tests for risky flows.

## 6. Fakes vs mocks

- Prefer hand-written fakes for code we own.
- Use `mocktail` for external collaborators.
- Assert on observable behavior.

## 7. Test data & fixtures

- One `test/fixtures/` folder with recorded JSON payloads.
- Builders for entity fixtures keep tests readable.
- Keep timestamps fixed for stable results.

## 8. Coverage policy

- High-risk files should be near 100% covered: auth/session, error mapping, money/quantity logic, permission gating.
- Screens rely more on widget and golden tests than line coverage alone.

## 9. CI gates

Every PR must pass:

1. `dart format --set-exit-if-changed .`
2. `flutter analyze` — 0 issues
3. `flutter test`
4. Optional integration / device gate

## 10. Manual QA checklist

- [ ] Fresh install → login → every screen renders.
- [ ] Airplane mode: clear message + Retry.
- [ ] Slow network: skeletons show, no blank screens.
- [ ] Rotation / tablet width: layout reflows.
- [ ] Largest system font: no clipped text.
- [ ] Dark mode: contrast remains good.
- [ ] Back navigation and deep link land correctly.
- [ ] Token expiry mid-session → clean redirect to login.
- [ ] Performance gate passed for new/changed screens.
