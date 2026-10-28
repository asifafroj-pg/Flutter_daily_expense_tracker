# Real-Time & Data Freshness

**This is the default data strategy for a modern Flutter app.** Screens should show live state, not stale snapshots from hours ago.

## Contents

1. [Freshness tiers](#1-freshness-tiers)
2. [Mechanisms](#2-mechanisms)
3. [Push (FCM)](#3-push-fcm)
4. [Polling — the default live mechanism](#4-polling--the-default-live-mechanism)
5. [App lifecycle](#5-app-lifecycle)
6. [Optimistic UI with rollback](#6-optimistic-ui-with-rollback)
7. [Connectivity & failure UX](#7-connectivity--failure-ux)
8. [Keeping the last good data on screen](#8-keeping-the-last-good-data-on-screen)

---

## 1. Freshness tiers

| Tier | Examples | Strategy |
|------|----------|----------|
| **Live** | Active items, counters, notifications | Push + poll every 5–15 s while visible |
| **Near-live** | Lists and collection screens | Push + poll on open + focus |
| **Warm** | Catalog or reference data | Fetch on open + pull-to-refresh |
| **Cold/static** | Profile or rarely changed data | Fetch once, refresh on request |

## 2. Mechanisms

| Need | Use |
|------|-----|
| Server → app event without user action | **FCM push** |
| Live view refresh while open | **`RealtimePoller`** or stream |
| User-initiated refresh | **Pull-to-refresh** |
| Re-entering after background | Lifecycle observer + refresh |

## 3. Push (FCM)

A push tells the app what changed; it should trigger a targeted refresh, not replace the full state.

## 4. Polling — the default live mechanism

```dart
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
}
```

The poll only refreshes; the bloc still owns state. Silent refreshes keep the current list visible and update it in place.

## 5. App lifecycle

Pause polling when the app is backgrounded and refresh when it resumes.

## 6. Optimistic UI with rollback

For safe, reversible mutations, apply the change locally immediately, then reconcile with the server. On failure, revert and surface a typed error.

## 7. Connectivity & failure UX

- Show a non-blocking offline banner if the network state changes.
- Use typed failures, not generic “something went wrong”.
- Distinguish server error, offline, and forbidden states.

## 8. Keeping the last good data on screen

A refresh must not blank the screen. Keep the last good data visible and add a subtle loading flag or last-updated text.
