# Offline Support (OPT-IN — read only when enabled for a feature)

> This is not the default. Most Flutter apps should assume connectivity and keep a highly responsive real-time UX. Offline support exists as an opt-in capability for features that truly need it.

## When to opt in

Only implement this when all of the following are true:

1. The feature is used in poor-connectivity environments.
2. The user must be able to read meaningful data without a network or queue a write that cannot be lost.
3. The feature is explicitly approved and added to the opt-in register.

Everything else fails fast with a typed error + retry.

## Wiring

```dart
sl.registerLazySingleton<ItemRepository>(() => ItemRepositoryImpl(
  remote: sl(),
  local: sl(),
  networkInfo: sl(),
  enableOffline: true,
));
```

`CacheService` and `OfflineQueue` should only be registered when a feature opts in.

---

## The rules (apply fully once opted in)

### 1. Bounded cache with TTL + eviction

Keep cached GET entries under a reasonable cap and evict expired or oldest entries first.

### 2. Cache invalidation on mutations

After a successful mutation, clear the cache entries for the affected resource and any related resources.

### 3. Offline write queue

Mutations that fail while offline can be stored and replayed when connectivity returns.

### 4. Stale-while-offline reads

If the network fails but cached data exists, serve the cache and avoid failing outright.

### 5. Consistent serialization

Cache JSON-decoded payloads, not raw Dart objects.

### 6. Pending-sync banner

Expose queue length to the app shell or a `Cubit` and show the sync count.

---

## MUST-NOT

1. Global offline machinery for every feature.
2. Returning `NetworkFailure` when a cached fallback exists.
3. No TTL or eviction policy.
4. Logging request/response bodies.
5. Treating offline mode as the default product experience.
