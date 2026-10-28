# BLoC Conventions

How we write state with **`bloc` + `flutter_bloc`**. Read
[`architecture.md`](architecture.md) §3 first for *when* to choose Bloc vs Cubit.

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
| Transitions are non-trivial | Auth session flag (`AuthCubit` alternative) |

Don't wrap a single `emit` in an event class. Don't turn a simple toggle into a
Bloc.

## 2. File & class layout

One feature concern = one bloc, in `features/<feature>/presentation/bloc/`:

```
bloc/
├── trip_list_bloc.dart     # class + part directives
├── trip_list_event.dart    # part of 'trip_list_bloc.dart';
└── trip_list_state.dart    # part of 'trip_list_bloc.dart';
```

Use `part`/`part of` for the triple (matches the reference app) **or** one sealed
file — pick one style per project and stay consistent. We use **`part`**.

## 3. Events

- Abstract base `extends Equatable`; `props` lists only *payload* fields.
- Name `<Verb><Subject>Event` (`LoadTripsEvent`, `StartTripEvent`).
- Mark "refresh" intent explicitly (`LoadTripsEvent(refresh: true)`).
- Internal/poll events are **private** (`_TripPollTick`).

```dart
part of 'trip_list_bloc.dart';

abstract class TripListEvent extends Equatable {
  const TripListEvent();
  @override
  List<Object?> get props => [];
}

class TripListStarted extends TripListEvent {
  const TripListStarted();
}

class TripListRefreshed extends TripListEvent {
  final bool silent;
  const TripListRefreshed({this.silent = false});
  @override
  List<Object?> get props => [silent];
}

class TripStatusChanged extends TripListEvent {
  final String tripId;
  final TripStatus status;
  const TripStatusChanged({required this.tripId, required this.status});
  @override
  List<Object?> get props => [tripId, status];
}

class _TripPollTick extends TripListEvent { const _TripPollTick(); }
```

## 4. States

- Abstract base `extends Equatable`.
- The lifecycle phases are `Initial`, `Loading`, `Loaded`, `Empty`, `Error`.
- **`Loaded` carries freshness + busy flags** (`isRefreshing`, `isSubmitting`,
  `lastUpdatedAt`, non-fatal `error`) so refreshes never blank the screen.
- `copyWith` is manual; the `error` field is **not preserved** across `copyWith`
  (pass it explicitly to clear/set) to avoid stale error banners.
- Never store raw `Map` in `props`.

```dart
part of 'trip_list_bloc.dart';

abstract class TripListState extends Equatable {
  const TripListState();
  @override
  List<Object?> get props => [];
}

class TripListInitial extends TripListState { const TripListInitial(); }
class TripListLoading extends TripListState { const TripListLoading(); }
class TripListEmpty extends TripListState { const TripListEmpty(); }

class TripListLoaded extends TripListState {
  final List<TripEntity> trips;
  final int page;
  final bool hasMore;
  final bool isRefreshing;
  final bool isSubmitting;
  final DateTime? lastUpdatedAt;
  final String? error;

  const TripListLoaded({
    required this.trips,
    required this.page,
    required this.hasMore,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.lastUpdatedAt,
    this.error,
  });

  TripListLoaded copyWith({
    List<TripEntity>? trips, int? page, bool? hasMore,
    bool? isRefreshing, bool? isSubmitting, DateTime? lastUpdatedAt, String? error,
  }) => TripListLoaded(
        trips: trips ?? this.trips,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        error: error, // intentionally not preserved
      );

  @override
  List<Object?> get props =>
      [trips, page, hasMore, isRefreshing, isSubmitting, lastUpdatedAt, error];
}

class TripListError extends TripListState {
  final String message;
  const TripListError({required this.message});
  @override
  List<Object?> get props => [message];
}
```

## 5. Handlers — the fold rule

Every use case returns `Either<Failure, T>`. **Fold it**; never let an exception
escape a handler.

```dart
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final GetTripsUseCase _getTrips;
  final ChangeTripStatusUseCase _changeStatus;

  TripListBloc({required GetTripsUseCase getTrips, required ChangeTripStatusUseCase changeStatus})
      : _getTrips = getTrips,
        _changeStatus = changeStatus,
        super(const TripListInitial()) {
    on<TripListStarted>((e, emit) => _load(emit, page: 1, silent: false));
    on<TripListRefreshed>((e, emit) => _load(emit, page: 1, silent: e.silent));
    on<TripStatusChanged>(_onStatusChanged);
    on<_TripPollTick>((e, emit) => _load(emit, page: 1, silent: true));
  }

  Future<void> _load(Emitter<TripListState> emit,
      {required int page, required bool silent}) async {
    final current = state;
    if (!silent) {
      emit(const TripListLoading());
    } else if (current is TripListLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }

    final result = await _getTrips(page: page);
    result.fold(
      (f) => emit(const TripListError(message: 'Could not load trips')), // + retry
      (trips) => trips.isEmpty
          ? emit(const TripListEmpty())
          : emit(TripListLoaded(
              trips: trips, page: page, hasMore: trips.isNotEmpty,
              lastUpdatedAt: DateTime.now(),
            )),
    );
  }
}
```

- Show a **typed, user-facing** message, not `failure.toString()`.
- Keep the last good `Loaded` state on a **silent** refresh failure (set `error`
  on the loaded state instead of replacing it).

## 6. Pagination

Batch, discovery-triggered loads; append; guard against duplicate in-flight calls.

```dart
on<TripListLoadMore>(_onLoadMore);

Future<void> _onLoadMore(TripListLoadMore e, Emitter<TripListState> emit) async {
  final current = state;
  if (current is! TripListLoaded || !current.hasMore || current.isRefreshing) return;

  emit(current.copyWith(isRefreshing: true));
  final result = await _getTrips(page: current.page + 1);
  result.fold(
    (f) => emit(current.copyWith(isRefreshing: false, error: 'Could not load more')),
    (more) => emit(TripListLoaded(
      trips: [...current.trips, ...more],
      page: current.page + 1,
      hasMore: more.isNotEmpty,
      lastUpdatedAt: DateTime.now(),
    )),
  );
}
```

Trigger `TripListLoadMore` when the list scrolls near the end (e.g. `itemCount - 3`).

## 7. Busy flags & one-shot errors

- **Submitting a mutation**: set `isSubmitting`/`busyId` on the loaded state so
  the button shows progress and double-taps are ignored.
- **One-shot errors** (snackbar/banner): emit the error **once** from the handler
  via a `BlocListener`. If the error lives in `Loaded.error`, clear it after
  showing (`add` a `TripListErrorDismissed` event) so it doesn't re-fire.

## 8. UI binding

**Per-screen (preferred).** Create the bloc at the screen, dispatch the initial
event, and close it with the screen (`registerFactory` + `BlocProvider`).

```dart
class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TripListBloc>()..add(const TripListStarted()),
      child: const _TripListView(),
    );
  }
}

class _TripListView extends StatelessWidget {
  const _TripListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: BlocConsumer<TripListBloc, TripListState>(
        listener: (context, state) {
          final msg = switch (state) {
            TripListLoaded(:final error?) => error,
            TripListError(:final message) => message,
            _ => null,
          };
          if (msg != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (context, state) => switch (state) {
          TripListInitial() || TripListLoading() => const _TripListSkeleton(),
          TripListEmpty() => const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No trips yet',
              description: 'Assigned trips will appear here.',
            ),
          TripListError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<TripListBloc>().add(const TripListRefreshed()),
            ),
          TripListLoaded(:final trips, :final isRefreshing) => RefreshIndicator(
              onRefresh: () async =>
                  context.read<TripListBloc>().add(const TripListRefreshed()),
              child: Column(children: [
                if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.builder(
                    itemCount: trips.length,
                    itemBuilder: (_, i) => TripCard(trip: trips[i]),
                  ),
                ),
              ]),
            ),
        },
      ),
    );
  }
}
```

- Prefer **`switch` expressions over sealed states** — exhaustive, no `else`.
- **Root scope only for `AuthBloc`** (and the offline banner cubit if used).
  Never mount every feature bloc at the app root.
- Read states with `BlocBuilder`/`BlocSelector`; dispatch with
  `context.read<MyBloc>().add(...)` **inside callbacks only**.

### `setState` vs the bloc — which state lives where

`setState` is **not** incompatible with the BLoC pattern. What decides is the
*kind* of state, not which API holds it:

| State | Holder |
|-------|--------|
| Business / shared / persisted / testable (session, trips, counters, filters, form results) | **Bloc or Cubit** — never `setState` |
| Ephemeral, view-only, owned by one widget (password show/hide, a local animation flag, whether a sheet is open) | A local `ValueNotifier` — `setState` is allowed **only** here |

Two hard rules, both performance-critical:

1. **No `setState` over a whole form or screen.** One eye-toggle must not rebuild
   the email field and the button beside it.
2. **Scope bloc reads.** Never `context.watch<MyBloc>()` in a form/screen's root
   `build()` — it rebuilds every child on every state change. Read only what the
   widget displays via `BlocSelector` / `BlocBuilder(buildWhen:)`, or mirror the
   flag into a `ValueNotifier` so each leaf listens to exactly what it needs.

```dart
// ✅ Owned by the form (no setState). Rebuilds only this field.
class PasswordField extends StatelessWidget {
  const PasswordField({required this.controller, required this.obscure});

  final TextEditingController controller;
  final ValueNotifier<bool> obscure;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: obscure,
    builder: (BuildContext context, Widget? _) =>
        AppTextField(controller: controller, obscureText: obscure.value),
  );
}
```

Real numbers from this refactor: see [`performance-login.md`](performance-login.md).

## 9. Real-time integration

- Live/near-live blocs own a `RealtimePoller` and handle internal poll events; see
  [`realtime.md`](realtime.md).
- Pause polling on `AppLifecycleState.paused`, refresh + resume on `resumed`, and
  cancel in `close()`.
- FCM events are routed to the blocs that need refreshing (usually via a refresh
  event, or a global `RefreshBus`/stream).

## 10. Testing

Bloc logic is tested with **`bloc_test`** (`blocTest<B, E, S>`). Full doctrine in
[`qa.md`](qa.md).

```dart
blocTest<TripListBloc, TripListState>(
  'emits [Loading, Loaded] when GetTripsUseCase succeeds',
  build: () {
    when(() => getTrips.call(page: 1)).thenAnswer((_) async => Right([tTrip]));
    return TripListBloc(getTrips: getTrips, changeStatus: changeStatus);
  },
  act: (b) => b.add(const TripListStarted()),
  expect: () => [
    const TripListLoading(),
    isA<TripListLoaded>().having((s) => s.trips, 'trips', hasLength(1)),
  ],
  verify: (_) => verify(() => getTrips.call(page: 1)).called(1),
);
```

## 11. MUST-NOT list

1. Constructing a bloc with `new` in a widget — always `sl<MyBloc>()` +
   `registerFactory`.
2. `MultiBlocProvider` at the app root mounting every bloc / auto-dispatching all
   initial events at startup.
3. Business logic in the widget or in a datasource.
4. `emit` after the bloc is closed (guard async completions / use `emit.isDone`).
5. Blanking a loaded screen on a silent refresh.
6. Emitting a raw `Exception` message to the UI.
7. Reusing one bloc instance across screens (`registerSingleton` for a feature
   bloc is a bug except `AuthBloc`).
8. Storing `BuildContext` inside the bloc.
9. `copyWith` that silently preserves `error` and causes a snackbar loop.
10. Polling that keeps running when the screen is disposed or the app is paused.
