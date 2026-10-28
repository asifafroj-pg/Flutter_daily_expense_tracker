# Real-Time & Data Freshness

**This is the default data strategy for Parafleet. Assume the network is
present.** Screens must show *live* state, not a snapshot from hours ago.
Offline is a separate, opt-in concern — see [`offline-optional.md`](offline-optional.md).

## Contents

1. [Freshness tiers](#1-freshness-tiers)
2. [Mechanisms](#2-mechanisms)
3. [Push (FCM)](#3-push-fcm)
4. [Polling — the default live mechanism](#4-polling--the-default-live-mechanism)
5. [App lifecycle](#5-app-lifecycle)
6. [Optimistic UI with rollback](#6-optimistic-ui-with-rollback)
7. [Conflicts & concurrency](#7-conflicts--concurrency)
8. [Connectivity & failure UX](#8-connectivity--failure-ux)
9. [Keeping the last good data on screen](#9-keeping-the-last-good-data-on-screen)
10. [Testing real-time behaviour](#10-testing-real-time-behaviour)

---

## 1. Freshness tiers

Classify every screen before you build it. The tier dictates the mechanism.

| Tier | Examples | Strategy |
|------|----------|----------|
| **Live** | Active trip tracking, dispatch status, gate/weighbridge events, live counters | Push + poll every **5–15 s while visible** |
| **Near-live** | Assignment offers, quotations, bills, claims, performance | Push + poll every **30–60 s while visible**, refresh on focus |
| **Warm** | Vehicle/driver lists, tenders, rates | Fetch on open + **pull-to-refresh**, invalidate on push |
| **Cold/static** | Reference data (vehicle types, locations, units), profile | Fetch once, refresh on explicit pull or push |

Rules:
- **Never poll a screen that isn't visible.** Cancel timers in `close()`/`dispose`.
- **Never poll faster than the server allows.** Agree an interval with backend;
  default 15 s for live, 60 s for near-live.
- **Event-driven beats polling** where the backend can push.

## 2. Mechanisms

| Need | Use |
|------|-----|
| Server → app event without user action | **FCM push** (`NotificationService`) |
| Live view refresh while open | **`RealtimePoller`** inside the feature bloc |
| Real-time bidirectional (if backend adds it) | **WebSocket/SSE** in `RealtimeService` |
| User-initiated refresh | **`RefreshIndicator`** (pull-to-refresh) |
| Re-entering after background | lifecycle observer → refresh + resume poll |

The TMS API is REST today, so **push + polling** is the baseline. If a
WebSocket/SSE endpoint is added, put it behind `RealtimeService` and expose a
`Stream<T>`; blocs subscribe to it instead of polling. Do not scatter raw
`socket.listen` calls across features.

## 3. Push (FCM)

`NotificationService` owns token registration, foreground handling and payload →
route mapping. **A push tells the app *what changed*, not the full new state** —
after receiving it, refresh the affected data from the API (single source of
truth).

```dart
/// Maps an FCM payload to the route to open and the feature to refresh.
class PushRoute {
  final String location;      // e.g. '/trips/123'
  final String? invalidate;   // e.g. 'trips' — the feature key to refresh

  const PushRoute(this.location, {this.invalidate});
}

PushRoute? routeFor(RemoteMessage m) {
  switch (m.data['type']) {
    case 'trip.status_changed':
      return PushRoute(AppPages.tripDetail(m.data['id']!), invalidate: 'trips');
    case 'assignment.offer':
      return PushRoute(AppPages.assignmentDetail(m.data['id']!), invalidate: 'assignments');
    case 'bill.generated':
      return PushRoute(AppPages.billDetail(m.data['id']!), invalidate: 'bills');
    default:
      return null;
  }
}
```

- Register/refresh the FCM token **per authenticated session**; delete it on logout.
- Oversize/silent payloads still just trigger a refetch.
- Open the target with `NavigationService.navigateTo(AppPages.x)`; every payload
  route must be an `AppPages` constant and **permission-gated** (see
  [`security.md`](security.md) and [`navigation.md`](navigation.md)).

## 4. Polling — the default live mechanism

Put polling in a small reusable helper, not duplicated per bloc. It must be
cancellable and respectful of lifecycle.

```dart
/// Repeatedly invokes [tick] on [interval] until [stop] is called.
/// Only run while the owning screen is visible (see §5).
class RealtimePoller {
  final Duration interval;
  final Future<void> Function() tick;
  Timer? _timer;

  RealtimePoller({required this.interval, required this.tick});

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => tick());
  }

  void stop() => _timer?.cancel();
  void resumeIfStopped() => _timer ??= Timer.periodic(interval, (_) => tick());
}
```

Wiring it into a bloc — the poll only refreshes; the bloc still owns state:

```dart
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final GetTripsUseCase _getTrips;
  RealtimePoller? _poller;

  TripListBloc({required GetTripsUseCase getTrips})
      : _getTrips = getTrips,
        super(const TripListInitial()) {
    on<TripListStarted>(_onStarted);
    on<TripListRefreshed>(_onRefresh);
    on<_TripPollTick>(_onRefresh); // internal, silent refresh
  }

  Future<void> _onStarted(TripListStarted e, Emitter<TripListState> emit) async {
    await _load(emit, silent: false);
    _poller = RealtimePoller(
      interval: const Duration(seconds: 15),
      tick: () async => add(const _TripPollTick()),
    )..start();
  }

  // ...
  @override
  Future<void> close() {
    _poller?.stop();
    return super.close();
  }
}
```

- A poll tick is a **silent refresh**: keep the current list on screen, update it
  in place, and never flash a loading spinner (see §9).
- Back off on repeated failures (e.g. 15 s → 30 s → 60 s, cap 2 min) and reset on
  success.

## 5. App lifecycle

Polling must pause when the app is backgrounded and refresh when it resumes.

```dart
class _TripListScreenState extends State<TripListScreen> with WidgetsBindingObserver {
  late final TripListBloc _bloc = sl<TripListBloc>()..add(const TripListStarted());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc.add(const TripListRefreshed());
      _bloc.add(const TripListResumePoll());
    } else {
      _bloc.add(const TripListPausePoll());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }
}
```

Also refresh on **route re-entry** (returning to a screen from a detail page) for
Live/Near-live tiers.

## 6. Optimistic UI with rollback

For fast, low-risk mutations (acknowledge, start trip, mark delivered), apply the
change locally immediately, then reconcile.

```dart
Future<void> _onStartTrip(StartTripEvent e, Emitter<TripListState> emit) async {
  final current = state;
  if (current is! TripListLoaded) return;

  // 1. Optimistically apply
  emit(current.copyWith(
    trips: current.trips.map((t) => t.id == e.id ? t.copyWith(status: TripStatus.started) : t).toList(),
  ));

  // 2. Reconcile with server
  final result = await _startTrip(id: e.id);
  result.fold(
    (failure) async {
      // 3. Roll back + surface the error
      emit(current.copyWith(error: failure.message));
      add(const TripListRefreshed()); // resync to truth
    },
    (trip) {
      emit(current.copyWith(
        trips: current.trips.map((t) => t.id == trip.id ? trip : t).toList(),
      ));
    },
  );
}
```

**Use optimistic updates only for reversible, idempotent-ish actions.** For
money, approvals, or anything irreversible, show a blocking progress state and
wait for the server.

## 7. Conflicts & concurrency

- Prefer a server **`updatedAt` / version** field when present; if the server
  rejects a stale write (409), refetch and re-apply.
- Two users editing the same record: the server wins. On `409 CONFLICT`, refresh
  the record and show a clear message.
- Never merge silently. Never keep a "dirty" local copy that differs from the
  server without telling the user.

## 8. Connectivity & failure UX

- `connectivity_plus` drives a non-blocking **offline banner** — it does **not**
  block navigation or hide data already on screen.
- When a request fails due to connectivity: show an inline error with **Retry**;
  for Live tier also keep polling (it will recover automatically).
- Distinguish **no network** from **server error** from **forbidden** in the UI —
  use the typed `Failure`, never a generic "something went wrong" for everything.
- Never retry non-idempotent writes blindly; use the server's idempotency key if
  provided.

## 9. Keeping the last good data on screen

A refresh must not blank the screen. Model freshness explicitly in the state:

```dart
class TripListLoaded extends TripListState {
  final List<TripEntity> trips;
  final bool isRefreshing;      // subtle indicator, data still visible
  final DateTime? lastUpdatedAt;
  final String? error;          // non-fatal error from a background refresh

  // ...
}
```

- First load → `Loading` (skeleton).
- Refresh of already-loaded data → keep `Loaded`, set `isRefreshing: true`, show a
  thin progress bar. On error keep the data and set `error`.
- Show "Updated just now / 2 min ago" so users trust freshness.

## 10. Testing real-time behaviour

- Inject a **fake clock / fake poller** — never `await Future.delayed` in tests.
  Use `fake_async` (`package:fake_async`, ships with `flutter_test`).
- Test a poll tick with `blocTest`: feed the silent-refresh event and assert the
  state updates **without** passing through `Loading`.
- Test rollback: make the use case return `Left`, assert the optimistic change is
  reverted and the error is emitted.
- See [`qa.md`](qa.md) for the full testing doctrine.
