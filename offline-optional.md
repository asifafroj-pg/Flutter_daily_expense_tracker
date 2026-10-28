# Offline Support (OPT-IN — read only when enabled for a feature)

> **This is NOT the default.** Parafleet is a real-time app (see
> [`realtime.md`](realtime.md)) and assumes the network is present. Offline
> support exists as an **opt-in capability** for a small set of features that
> genuinely need it.

## When to opt in

Only implement this when **all** are true:

1. The feature is used in places with sustained poor connectivity (remote yards,
   weighing points, moving vehicles).
2. The user must be able to **read** something meaningful with no network, or
   **queue a write** that must not be lost.
3. You have a **design review sign-off** and the feature is added to the
   opt-in register below.

Everything else **fails fast** with a typed error + retry (see
[`realtime.md`](realtime.md) §8).

### Opt-in register

| Feature | Offline reads (TTL) | Offline writes | Owner |
|---------|--------------------:|---------------:|-------|
| _(none yet)_ | — | — | — |

## Wiring

Offline is **per-repository**, never global. Pass the flag at construction:

```dart
sl.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(
      remote: sl(),
      local: sl(),           // only inject the local source when opted in
      networkInfo: sl(),
      enableOffline: true,   // ← explicit, greppable, reviewed
    ));
```

`CacheService` and `OfflineQueue` are only registered/used by opted-in features.
A feature that is *not* opted in must not import them.

---

## The rules (apply fully once opted in)

### 1. Bounded cache with TTL + eviction

Cap cached GET entries at ≈200. Each entry stores `data`, `expiry`, `created`
(epoch ms). On write, if over the cap: drop **expired** entries first, then the
**oldest** until under the cap. Run a background sweep every ~15 min.

Default TTLs:

| Resource type | TTL |
|---------------|-----|
| List/collection endpoints | 5 min |
| Detail endpoints | 15 min |
| Profile / settings | 1 h |
| Static reference data | 24 h |

### 2. Cache invalidation on mutations

Every successful non-GET (2xx) purges the cached GET entries of the touched
resource, plus cross-resource aliases.

```dart
List<String> prefixesForMutation(Uri uri) {
  final s = uri.pathSegments;                 // ['api','v1','trips','123']
  if (s.length < 3) return [];
  final root = '/api/${s[1]}/${s[2]}';
  switch (s[2]) {
    case 'trips':
    case 'assignments':
    case 'bills':
      return [root, '/api/${s[1]}/dashboard', '/api/${s[1]}/notifications'];
    default:
      return [root];
  }
}
```

`clearByPrefixes(prefixes)` deletes keys whose path `== prefix` or is nested
under `prefix/`. Cache keys are `METHOD:/path?query`.

### 3. Offline write queue

Mutations that fail while offline are persisted and replayed when connectivity
returns — actions never silently vanish.

Enqueue on offline errors, **skipping**:
- `FormData` requests (uploads — too large to persist reliably; surface a
  "saved as draft" state instead).
- Requests with `extra['queue'] == false` (idempotency-sensitive / one-shot).
- Non-JSON-safe bodies.

Replay with a **fresh Dio carrying only the auth interceptor** (avoid
interceptor recursion — the cache/logger/offline interceptors must not re-enqueue
during replay). On replay:

- **2xx** → remove from queue + purge related cache prefixes.
- **4xx** → drop the request (server rejected; don't poison-pill retry).
- **5xx** → keep and retry later.
- Still-offline (connection error/timeout) → stop replay, retry on reconnect.

Triggers: **app launch** and **reconnection** (listen to `ConnectivityService`).

### 4. Stale-while-offline reads

On network error, serve the last cached body (ignore TTL) so screens keep data.
**Never return `Left(NetworkFailure)` when a cached copy exists.**

```dart
try {
  final raw = await _remote.getTrips(page: page);
  await _local.cache(key, raw, ttl: const Duration(minutes: 5));
  return Right(_parse(raw));
} on NetworkException {
  final stale = await _local.getStale(key);          // ★ cache before failing
  if (stale != null) return Right(_parse(stale));
  return const Left(NetworkFailure());
}
```

### 5. Consistent serialization

Cache stores **JSON-decoded payloads** (`Map`/`List`), never typed objects, and
reads back through the same `Model.fromJson(...)` used for network responses. A
round-trip must be indistinguishable from a network response.

### 6. Cache service interface

```dart
abstract class CacheService {
  Future<void> init();
  Future<void> close();
  Future<dynamic> read(String key, {bool allowStale = false});
  Future<dynamic> getStale(String key);
  Future<void> write(String key, dynamic data, {Duration ttl = const Duration(minutes: 5)});
  Future<void> delete(String key);
  Future<int> clearByPrefixes(List<String> prefixes);
  Future<void> clearAll();     // used on login/logout
  Future<int> size();
  Future<int> sweepNow();      // for tests
}
```

### 7. Pending-sync banner (BLoC version)

Expose the queue length as a `Cubit` watched by the app shell — no Riverpod.

```dart
class OfflineSyncCubit extends Cubit<int> {
  final OfflineQueue _queue;
  StreamSubscription<int>? _sub;

  OfflineSyncCubit(this._queue) : super(0) {
    _sub = _queue.pendingCountStream.listen(emit);
  }

  Future<void> syncNow() => _queue.replayAll();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
```

The shell watches it with `BlocBuilder<OfflineSyncCubit, int>` and shows a
material banner with a **Sync now** action when the count is `> 0`.

---

## Self-check before shipping an opted-in feature

- [ ] `CacheService` caps at ≈200, drops expired-then-oldest on write, sweeps
      every 15 min.
- [ ] Every successful non-GET clears the matching cache prefixes (+ aliases).
- [ ] Every mutating call enqueues offline failures (except FormData / opt-out /
      non-JSON).
- [ ] `OfflineQueue.replayAll()` runs on launch and reconnect, uses a fresh
      auth-only Dio, removes on 2xx, drops on 4xx, stops while offline.
- [ ] Pending-sync banner shows the count with a manual Sync action.
- [ ] Reads serve `getStale(...)` before returning `Left(NetworkFailure)`.
- [ ] `clearAll()` is awaited on login/logout **before** the first screen renders.
- [ ] All cache writes go through `jsonEncode` — no raw Dart objects in the box.

## MUST-NOT

1. **Mixed cache exceptions** — local sources throw `CacheException`; repositories
   catch it and return `Left(CacheFailure())`. Never mix `CacheException` /
   `CacheFailure` as throw/return.
2. **Catching `on Failure` for remote calls** — remote sources throw
   `ServerException`; repositories map it to `ServerFailure`. Don't let it leak.
3. **No TTL / eviction** — ubounded cache copies stale data forever.
4. **Offline read returning an error when cache exists** — always try `getStale`.
5. **No write queue** — user edits silently lost offline.
6. **One-shot connectivity boolean checked inside the repository only** — use the
   reactive `ConnectivityService` stream for UI + queue triggers.
7. **Global offline machinery** — offline is opt-in per feature, not app-wide.
8. **Logging bodies** in release.
