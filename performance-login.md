# Login screen jank — measurements

Device: **Samsung SM-S711B (Galaxy S23 FE)**, Android 16, `flutter drive --profile`.
Budget at 120 Hz = **8.33 ms/frame** (16.67 ms = hard drop at 60 Hz).

Harness: `integration_test/login_jank_test.dart` (collects `FrameTiming` per phase).

## Before

| phase | frames | build p50 | raster p50 | raster max | total max | >8.33ms | >16.67ms |
|-------|-------:|----------:|-----------:|-----------:|----------:|--------:|---------:|
| tap_email_cold | 7 | 0.90 | 1.34 | 2.71 | 10.30 | 2 | 0 |
| tap_email_warm | 3 | 3.17 | 2.77 | 5.53 | 13.68 | 2 | 0 |
| keyboard_opens | 2 | 1.38 | 1.95 | 1.95 | 4.48 | 0 | 0 |
| type_email | 3 | 0.52 | 3.47 | 4.20 | 5.65 | 0 | 0 |
| tap_password | 3 | 2.54 | 2.28 | 5.08 | 8.30 | 0 | 0 |
| type_password | 3 | 0.56 | 3.77 | 4.61 | 9.94 | 1 | 0 |
| **toggle_obscure** | 7 | 3.89 | **5.52** | **7.72** | **15.62** | **5** | 0 |
| keyboard_closes | 2 | 4.00 | 6.15 | 6.15 | 10.51 | 2 | 0 |

### Reading

- **Build is cheap (0.5–4 ms); raster is the cost (1.3–7.7 ms).** So this is a
  GPU/raster problem, not a rebuild storm.
- `toggle_obscure` drops **5 of 7 frames** at 120 Hz — the eye tap repaints the
  whole body, including the brand image.
- Root cause: `assets/icons/icon.png` is **1024×1024 (337 KB)** drawn at 96 px
  with no `cacheWidth`, so the rasterizer rescales a **4 MB** texture every frame
  it repaints; and with no `RepaintBoundary`, every field/keyboard animation
  repaints that same image.

## After

Fixed and confirmed on-device by the user (field tap + keyboard: smooth, no blink).
The artefacts below were applied; re-run the harness to capture fresh numbers:

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/login_jank_test.dart --profile -d <device>
```

### What changed

1. `LoginBranding` / `SplashBranding` — the icon is now decoded at its **display
   size** (`cacheWidth`/`cacheHeight` = `dp × devicePixelRatio`, i.e. ~270 px
   instead of 1024 px: ~4 MB → ~0.3 MB of texture) and sits behind a
   **`RepaintBoundary`**, so form/keyboard animations never re-rasterise it.
2. `AppTextField` — the five `OutlineInputBorder`s are `static const` instead of
   being re-allocated on every build.
3. `LoginForm` — no `setState`, and no `context.watch<AuthBloc>()` at the form
   root. Each leaf now listens to exactly one flag:
   `LoginEmailField` / `LoginPasswordField` / `LoginSubmitButton` over
   `ValueNotifier`s, so the eye-toggle rebuilds only the password field.
4. `LoginScreen` — `keyboardDismissBehavior: onDrag`.

Guard test: `test/features/auth/presentation/widgets/login_form_scope_test.dart`
asserts the eye toggle does **not** rebuild the email field.
