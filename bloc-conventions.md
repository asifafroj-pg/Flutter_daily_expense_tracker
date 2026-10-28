# BLoC Conventions

How we write state with **`bloc` + `flutter_bloc`**. Read [`architecture.md`](architecture.md) first for when to choose Bloc vs Cubit.

## Contents

1. [Bloc vs Cubit — decide, don't default](#1-bloc-vs-cubit--decide-dont-default)
2. [File & class layout](#2-file--class-layout)
3. [Events](#3-events)
4. [States](#4-states)
5. [Handlers — the fold rule](#5-handlers--the-fold-rule)
6. [Pagination](#6-pagination)
7. [Busy flags & one-shot errors](#7-busy-flags--one-shot-errors)
8. [UI binding](#8-ui-binding)
9. [Real-time integration](#9-real-time-integration)
10. [Testing](#10-testing)
11. [MUST-NOT list](#11-must-not-list)

---

## 1. Bloc vs Cubit — decide, don't default

| Use **Bloc** | Use **Cubit** |
|--------------|---------------|
| Multiple typed events (load, refresh, filter, mutate, paginate) | One concern with simple set/reset methods |
| Event audit trail matters | Nav index, theme toggle, filter form, form field validity |
| Transitions are non-trivial | Session flag or cached preferences |

Don't wrap a single `emit` in an event class. Don't turn a simple toggle into a Bloc.

## 2. File & class layout

One feature concern = one bloc, in `features/<feature>/presentation/bloc/`:

```
bloc/
├── item_list_bloc.dart
├── item_list_event.dart
└── item_list_state.dart
```

Use `part`/`part of` or a sealed file, but pick one style per project and stay consistent.

## 3. Events

- Abstract base `extends Equatable`; `props` lists only payload fields.
- Name `<Verb><Subject>Event` (`LoadItemsEvent`, `SubmitFormEvent`).
- Mark “refresh” intent explicitly.
- Internal/poll events are private.

```dart
part of 'item_list_bloc.dart';

abstract class ItemListEvent extends Equatable {
  const ItemListEvent();
  @override
  List<Object?> get props => [];
}

class ItemListStarted extends ItemListEvent {
  const ItemListStarted();
}

class ItemListRefreshed extends ItemListEvent {
  final bool silent;
  const ItemListRefreshed({this.silent = false});
  @override
  List<Object?> get props => [silent];
}
```

## 4. States

- Abstract base `extends Equatable`.
- Lifecycle phases are `Initial`, `Loading`, `Loaded`, `Empty`, `Error`.
- `Loaded` carries freshness + busy flags.
- `copyWith` is manual; `error` is not preserved across `copyWith` by default to prevent stale banners.

```dart
abstract class ItemListState extends Equatable {
  const ItemListState();
  @override
  List<Object?> get props => [];
}

class ItemListInitial extends ItemListState { const ItemListInitial(); }
class ItemListLoading extends ItemListState { const ItemListLoading(); }
class ItemListEmpty extends ItemListState { const ItemListEmpty(); }

class ItemListLoaded extends ItemListState {
  final List<ItemEntity> items;
  final int page;
  final bool hasMore;
  final bool isRefreshing;
  final bool isSubmitting;
  final DateTime? lastUpdatedAt;
  final String? error;

  const ItemListLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.lastUpdatedAt,
    this.error,
  });

  ItemListLoaded copyWith({
    List<ItemEntity>? items,
    int? page,
    bool? hasMore,
    bool? isRefreshing,
    bool? isSubmitting,
    DateTime? lastUpdatedAt,
    String? error,
  }) => ItemListLoaded(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        error: error,
      );

  @override
  List<Object?> get props => [items, page, hasMore, isRefreshing, isSubmitting, lastUpdatedAt, error];
}
```

## 5. Handlers — the fold rule

Every use case returns `Either<Failure, T>`. **Fold it**; never let an exception escape a handler.

```dart
class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  final GetItemsUseCase _getItems;

  ItemListBloc({required GetItemsUseCase getItems})
      : _getItems = getItems,
        super(const ItemListInitial()) {
    on<ItemListStarted>((e, emit) => _load(emit, page: 1, silent: false));
    on<ItemListRefreshed>((e, emit) => _load(emit, page: 1, silent: e.silent));
  }

  Future<void> _load(Emitter<ItemListState> emit, {required int page, required bool silent}) async {
    final current = state;
    if (!silent) {
      emit(const ItemListLoading());
    } else if (current is ItemListLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }

    final result = await _getItems(page: page);
    result.fold(
      (failure) => emit(const ItemListError(message: 'Could not load items')),
      (items) => items.isEmpty
          ? emit(const ItemListEmpty())
          : emit(ItemListLoaded(
              items: items,
              page: page,
              hasMore: items.isNotEmpty,
              lastUpdatedAt: DateTime.now(),
            )),
    );
  }
}
```

- Show a typed, user-facing message, not `failure.toString()`.
- Keep the last good `Loaded` state on a silent refresh failure.

## 6. Pagination

Batch, discovery-triggered loads; append; guard against duplicate in-flight calls.

## 7. Busy flags & one-shot errors

- Submitting a mutation: set `isSubmitting`/`busyId` on the loaded state.
- One-shot errors (snackbar/banner): emit once from the handler via a `BlocListener`.

## 8. UI binding

**Per-screen (preferred).** Create the bloc at the screen, dispatch the initial event, and close it with the screen.

```dart
class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ItemListBloc>()..add(const ItemListStarted()),
      child: const _ItemListView(),
    );
  }
}
```

- Prefer `switch` expressions over sealed states.
- Root scope only for `AuthBloc` and extremely app-wide state.
- Read states with `BlocBuilder`/`BlocSelector`; dispatch inside callbacks only.

### `setState` vs the bloc

`setState` is okay for ephemeral view-only state, not for business data.

## 9. Real-time integration

- Live/near-live blocs own a `RealtimePoller` or stream subscription.
- Refresh on resume, pause when the screen is not visible, and cancel in `close()`.
- Use push payloads to trigger a targeted refresh instead of building whole-state updates.

## 10. Testing

Use **`bloc_test`**. Every bloc should have tests for success, empty, error, and rollback paths.

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

## 11. MUST-NOT list

1. Constructing a bloc with `new` in a widget.
2. `MultiBlocProvider` at the app root mounting every bloc.
3. Business logic in the widget or in a datasource.
4. `emit` after the bloc is closed.
5. Blanking a loaded screen on a silent refresh.
6. Emitting a raw `Exception` message to the UI.
7. Storing `BuildContext` inside the bloc.
8. Polling without cancellation.
