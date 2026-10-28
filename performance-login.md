# Login screen jank — measurements

Device: representative test device, profile mode.
Budget at 120 Hz = **8.33 ms/frame**.

## Before

| phase | frames | build p50 | raster p50 | total max |
|-------|--------|-----------|------------|----------|
| tap_email_cold | 7 | 0.90 | 1.34 | 10.30 |
| toggle_obscure | 7 | 3.89 | 5.52 | 15.62 |

### Reading

- Build cost is low; raster is the expensive phase.
- A large static asset painted in the same layer as the form can re-rasterize every frame.
- Root cause is usually expensive painting or a whole-screen rebuild.

## After

Fixed by decoupling the static branding from the form area and by scoping rebuilds to only the relevant widgets.

### What changed

1. The static branding asset is decoded at display size and sits behind a `RepaintBoundary`.
2. Input borders are reused as static constants.
3. The form uses scoped rebuilds rather than rebuilding the full screen on every change.
4. Keyboard dismissal behavior is tuned to avoid unnecessary repaints.

Guard tests check that toggling an input state does not rebuild unrelated widgets.
