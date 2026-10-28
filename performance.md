# Performance & Frame Budget

> Performance is a feature, not a cleanup task.

The rule, in one line: after each screen is complete, profile it in release/profile mode; if it stutters, janks, blinks, freezes, or drops frames, fix it before moving on.

## 1. Frame budget

| Display | Frame budget | We must |
|---------|--------------|---------|
| 120 Hz | **8.3 ms** / frame | Hold 120 fps |
| 90 Hz | **11.1 ms** / frame | Hold 90 fps |
| 60 Hz | **16.7 ms** / frame | Hold 60 fps |

## 2. When this is mandatory

Run the performance gate after every screen is finished.

## 3. How to measure

Always measure in profile or release mode.

```bash
flutter run --profile --flavor dev --dart-define-from-file=config/dev.json
```

Use DevTools to inspect frame timings, widget rebuild counts, and raster spikes.

## 4. What to check per screen

- Screen build time
- Frame time and jank %
- Rebuild scope
- List performance
- Navigation smoothness
- Images decoding and caching
- Real-time tick behavior

## 5. Common causes → fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Janky scroll | Full list builds | Use `ListView.builder` |
| Build storms | Whole screen rebuilds | Scope with `BlocSelector` / `buildWhen` |
| Raster spikes | Heavy blur, clip, opacity | Replace with lighter visuals |
| Memory growth | Full-size image decode | Add `cacheWidth` / `cacheHeight` |
| Flicker | Element remounts | Keep layout stable and reuse widgets |

## 6. Anti-patterns (banned)

- `ListView(children: [...])` for data-driven lists
- `setState` for app data that belongs in a BloC/Cubit
- Heavy formatting in `build()`
- `UniqueKey()` in lists
- Large images without size hints
- `context.watch` at the root of a screen with unnecessary rebuilds

## 7. Performance acceptance checklist

- [ ] Screen builds and appears with no stall.
- [ ] Sustained 90–120 fps on high-refresh hardware; never below 60 fps.
- [ ] Zero jank during scroll, transitions, pull-to-refresh.
- [ ] Lists use `.builder` and only needed widgets rebuild.
- [ ] No blink/flash on load, refresh, navigate, rotate or theme switch.
- [ ] Images are size-hinted and cached.
- [ ] Realtime updates do not freeze the scroll.
