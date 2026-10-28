# Performance & Frame Budget

> **Performance is a feature, not a cleanup task.** Every screen is judged on how
> it renders the moment it is finished — not later, not "in the hardening pass".

**The rule, in one line:** after **each** screen is complete, profile it in
release/profile mode; if it stutters, janks, blinks, freezes, or drops frames,
**fix it before moving on**, and keep sustained rendering at **90–120 fps** on
high-refresh devices (**never below 60 fps** on 60 Hz displays).

## Contents

1. [Frame budget](#1-frame-budget)
2. [When this is mandatory](#2-when-this-is-mandatory)
3. [How to measure](#3-how-to-measure)
4. [What to check per screen](#4-what-to-check-per-screen)
5. [Common causes → fixes](#5-common-causes--fixes)
6. [Blinking / flicker](#6-blinking--flicker)
7. [Stuck / stalled (main-thread blows)](#7-stuck--stalled-main-thread-blows)
8. [Anti-patterns (banned)](#8-anti-patterns-banned)
9. [Performance acceptance checklist](#9-performance-acceptance-checklist)
10. [Reporting a screen](#10-reporting-a-screen)

---

## 1. Frame budget

| Display | Frame budget | We must |
|---------|--------------|---------|
| 120 Hz | **8.3 ms** / frame | Hold 120 fps; no dropped frames during scroll/animation. |
| 90 Hz | **11.1 ms** / frame | Hold 90 fps. |
| 60 Hz | **16.7 ms** / frame | Hold 60 fps at all times. |

Each frame has **two** phases, each with its own budget:

- **UI (build/layout)** — building + laying out the widget tree.
- **Raster (GPU)** — painting + compositing.

> **The target is the device's refresh rate, capped at 120.** Aim for 90–120 fps
> on capable hardware. A frame is "bad" if **build + raster exceeds the budget**
> or if any frame is missed during interaction (scroll, transition, animation).

**Hard rules**

- No screen may sustain < 60 fps.
- **Zero** jank frames during scroll, route transitions, and pull-to-refresh.
- No frame with **UI or raster > budget** in a normal interaction.
- No visible blink/flash during load, refresh, navigation or theme change.
- No ANR, frame freeze, or `Skipped N frames` on mid-range reference devices.

---

## 2. When this is mandatory

Run the [performance gate](#9-performance-acceptance-checklist) **after every
screen is finished** (and again after any change that touches it):

- a new screen / route,
- a list, grid, or scrollable,
- an animation or transition,
- a realtime screen (polling/streams) — **always**,
- a change to a shared widget, theme token, or image/asset.

It is part of [Definition of Done](definition-of-done.md) — the screen is **not
done** until it passes. "It looks fine on the emulator in debug" is **not** a
pass: profile/release only.

---

## 3. How to measure

Always measure in **profile** (or release) mode — debug is 10–100× slower and its
numbers are meaningless.

```bash
# 1. Profile on the target device
flutter run --profile --flavor dev --dart-define-from-file=config/dev.json

# 2. In-app: show the frame meter (per-frame UI + raster bars)
#    — in the app, open DevTools → Performance → "Performance overlay",
#      or set: MaterialApp(showPerformanceOverlay: true) temporarily.

# 3. DevTools (open from the run log URL)
flutter pub global activate devtools   # once
dart devtools
#    → Performance tab: Frame chart (UI/Raster), Timeline events, rebuild counts
#    → "Track widget builds" + "Highlight dirty widgets" to find rebuild storms

# 4. Android native frame stats (janky frames %, P50/P90/P95/P99)
adb shell dumpsys gfxinfo <package> reset
#    ...exercise the screen...
adb shell dumpsys gfxinfo <package>

# 5. Automated frame-time assertions in a test
flutter test integration_test --profile   # timed frames per interaction
```

- Read the **Flutter frame chart** in DevTools: green = UI, blue = raster. Any bar
  crossing its budget line = defect.
- Watch **rebuild counts** ("Track widget builds"): a static screen should barely
  rebuild; a list should rebuild only visible rows.
- Use `flutter run --profile --trace-skia` / Impeller diagnostics only when
  chasing raster spikes.
- Compare **cold start** and **first navigation to the screen** (shader/Impeller
  warm-up) — the first open must not jank.

---

## 4. What to check per screen

| Signal | Where | Pass looks like |
|--------|-------|-----------------|
| **Screen build time** | DevTools Timeline → first frame after push; `build` time | No single build > budget; screen appears without a stall. |
| **Frame time (UI + raster)** | DevTools frame chart | Every bar under budget; no spikes in interaction. |
| **Jank %** | `dumpsys gfxinfo`, DevTools | ~0% janky frames on normal scroll. |
| **Rebuild scope** | "Track widget builds" | Only changed subtrees rebuild; `const` widgets never rebuild. |
| **List performance** | Scroll fast | Steady fps; rows built lazily; no growth in memory. |
| **Navigation** | Push/pop the route | Transition animates at full fps; no blank frame. |
| **Images** | Load + scroll | Decoded off-thread, cached, no flicker, no full-size decode. |
| **Realtime** | Wait for a poll/stream tick | Tick updates only what changed; scroll stays smooth. |
| **Memory** | DevTools Memory | Flat while scrolling; no leak after push/pop ×10. |
| **Blink/flicker** | Enter, refresh, rotate, theme | No flash, no jump, no flash-of-wrong-image. |

---

## 5. Common causes → fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Janky scroll | `ListView(children: [...])` builds everything | `ListView.builder` / `.separated`; `SliverList.builder`. |
| Raster spikes | `BackdropFilter`, `ClipRRect`, `Opacity`, big shadows, blur | Avoid `BackdropFilter`; `ClipRRect` only when needed; `ImageFiltered` sparingly; prefer a pre-blurred asset. |
| Build storms | Whole screen rebuilds on state change | Scope with `BlocBuilder(buildWhen:)` / `BlocSelector`; split widgets; `const` subtrees. |
| Missed frames | `setState` over a big tree, heavy `build()` work | Precompute in the bloc/ViewModel; move formatting/maths out of `build`. |
| Memory growth | Images decoded at full res, listeners not disposed | `CacheWidth`/`CacheHeight`; `dispose()` controllers; cancel timers/streams. |
| First-open jank | Shader compilation | Impeller (default on modern Flutter); warm critical visuals; avoid exotic shaders. |
| Slow media list | `Image.network` no cache | `cached_network_image` + sized `memCacheWidth`. |
| **Flicker/stutter the moment a field is focused or the keyboard opens** | A large master asset drawn small, in the same layer as the form (every label/keyboard frame re-rasterises it) | `cacheWidth`/`cacheHeight` sized to `dp * devicePixelRatio`, **and** a `RepaintBoundary` around the static header. |

---

## 6. Blinking / flicker

A "blink" is a visible flash/flicker — always a defect. Common causes and cures:

- **Image placeholder → image swap** remounts → use
  `Image(..., gaplessPlayback: true)` and keep the frame mounted.
- **Skeleton swaps the whole widget** → keep the same layout; animate opacity,
  don't replace the subtree (keeps identity + avoids remount).
- **Keys changing every build** (e.g. `UniqueKey()`, `ObjectKey` on a rebuilt
  value) → widgets are thrown away and rebuilt. Use stable `ValueKey`s only.
- **Rebuilding the root theme / `MaterialApp`** on state change → theme and
  `MaterialApp` must not rebuild on data updates.
- **`AnimatedSwitcher`/`AnimatedCrossFade`** flipping on every parent rebuild →
  give a stable key and only switch on a real state change.
- **Refresh blanking the list** → keep last-good content on screen (silent
  refresh, `isRefreshing` flag), never swap to an empty state and back.
- **Theme/dark-mode flash** → resolve theme before first frame; don't apply it in
  a post-frame callback.
- **Flicker exactly when a field is focused or the keyboard opens** → a large
  master asset sits in the same layer as the form, so every label/keyboard frame
  re-rasterises it. Decode at display size
  (`cacheWidth: dp * MediaQuery.devicePixelRatioOf(context)`) and put the static
  header behind a `RepaintBoundary`. Worked example:
  [`performance-login.md`](performance-login.md).

---

## 7. Stuck / stalled (main-thread blows)

When the UI freezes or "sticks", the main isolate is busy. Fixes:

- **Parse large JSON off the main isolate** — `compute`/`Isolate` for big
  payloads; never `jsonDecode` a large body on the UI thread.
- **Never do sync I/O in `build`/`initState`** — read storage/prefs during
  bootstrap or in the bloc, not in widgets.
- **Bound the work per frame** — batch/limit list work, avoid O(n²) sorts per
  build, compute once in the bloc and cache.
- **Don't block on the network** — every call is async and state-driven.
- **Debounce** search/typing/filter; **throttle** scroll-driven work.
- **Cap realtime ticks** — re-render at most once per frame; coalesce burst
  updates in the bloc.

---

## 8. Anti-patterns (banned)

- `ListView(children: [...])` for data-driven / long lists.
- `Opacity`, `BackdropFilter`, `ClipRRect`, `ImageFilter.blur` wrapping large
  subtrees, and heavy `BoxShadow` in scrolling content.
- `setState` in `StatefulWidget` for data that belongs in a Bloc/Cubit.
- `BlocBuilder` wrapping a whole screen without `buildWhen`/`BlocSelector`.
- `Image.network`/`Image.asset` without size hints for large images.
- Formatting/maths/`jsonDecode` **inside** `build()`.
- `UniqueKey()` / unstable keys in lists.
- Animating layout properties (`width`, `height`, `padding`) instead of
  `Transform`/`Align`.
- Leaving the performance overlay on in a release build (it is a dev flag only).

---

## 9. Performance acceptance checklist

Run **after finishing each screen**, in profile mode on a representative
**mid-range** device (not the fastest phone you own):

- [ ] Screen builds and appears with **no stall** (build time within budget).
- [ ] **Sustained 90–120 fps** on high-refresh hardware; **never < 60 fps**.
- [ ] **Zero jank** during scroll, transitions, and pull-to-refresh.
- [ ] Frame chart: **no UI or raster bar over budget** during interaction.
- [ ] Lists use `.builder`; scrolling is smooth with the **longest** plausible data.
- [ ] Only the needed widgets rebuild (widget-build tracking); `const` stays const.
- [ ] Real-time tick / poll updates **only what changed**; scroll stays smooth.
- [ ] **No blink/flash** on load, refresh, navigate, rotate or theme switch.
- [ ] **No freeze/ANR**; large JSON parsed off the main isolate.
- [ ] Images decoded at target size, cached, no flicker; memory flat over scroll.
- [ ] Cold start and **first open** of the screen do not jank.
- [ ] No banned anti-pattern from [§8](#8-anti-patterns-banned) present.
- [ ] Any regression found is **fixed and re-profiled** (not deferred).

If any box fails → **stop and fix**. A screen that has not passed this gate is not
done ([`definition-of-done.md`](definition-of-done.md)).

---

## 10. Reporting a screen

Record a short block in the PR for every screen (attach a DevTools frame-chart
screenshot):

```text
Screen: TripListScreen
Device: <model>, 120 Hz, profile mode
Build (UI):  avg 3.1 ms   max 6.4 ms      (budget 8.3)
Raster:      avg 2.4 ms   max 5.9 ms      (budget 8.3)
Jank:        0% during 3 s fast scroll
Rebuilds:    only visible rows; const widgets stable
Issues found: skeleton flashed on refresh → kept last-good data (fixed)
Result:      PASS (90–120 fps held)
```

See also: [`ui-design.md`](ui-design.md) (tokens / widget choices),
[`realtime.md`](realtime.md) (refresh without blanking),
[`qa.md`](qa.md) §12 (performance testing), [`bloc-conventions.md`](bloc-conventions.md)
(keeping rebuilds scoped).
