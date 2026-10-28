# UI & Design System

The architecture keeps the code maintainable; the UI keeps it usable. Pull every
value from tokens — never inline magic numbers.

## Contents

1. [Responsiveness — flutter_screenutil](#1-responsiveness--flutter_screenutil)
2. [Design tokens](#2-design-tokens)
3. [Theming](#3-theming)
4. [Shared components](#4-shared-components)
5. [Aesthetics](#5-aesthetics)
6. [States: loading / empty / error](#6-states-loading--empty--error)
7. [Accessibility](#7-accessibility)
8. [Locale & content](#8-locale--content)
9. [Widget composition & screen size](#9-widget-composition--screen-size)

---

## 1. Responsiveness — flutter_screenutil

Design draft baseline **375 × 812**. Initialize once in `app.dart`.

```dart
ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  splitScreenMode: true,
  builder: (_, __) => MaterialApp.router(/* ... */),
)
```

Use extensions everywhere: `.w` (width), `.h` (height), `.sp` (font, respects
user scaling), `.r` (radius). **Raw `EdgeInsets` only for non-scaling spacing**
(e.g. keyboard insets).

Also use `LayoutBuilder`/`MediaQuery` for real breakpoints (phone vs tablet) —
`.w` scales, but it does not reflow. Lists use `.builder` (lazy) always.

## 2. Design tokens

`lib/app/core/theme/design_system.dart` — single source of truth.

```dart
class AppColors {
  AppColors._();

  // Brand (from the Parafleet logo)
  static const Color navy = Color(0xFF0F1B33);
  static const Color blue = Color(0xFF1E88E5);
  static const Color orange = Color(0xFFF5A623);
  static const Color green = Color(0xFF10B981);

  static const Color primary = blue;
  static const Color onPrimary = Colors.white;

  // Surfaces
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF16213A);

  // Text
  static const Color textPrimary = Color(0xFF0F1B33);
  static const Color textSecondary = Color(0xFF5B6779);
  static const Color textDisabled = Color(0xFF9AA4B2);
  static const Color textOnDark = Colors.white;

  // Status
  static const Color success = green;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = blue;

  // Borders, dividers, shadows
  static const Color border = Color(0xFFE3E8EF);
  static const Color divider = Color(0xFFF1F4F8);
  static Color shadow = const Color(0xFF0F1B33).withOpacity(0.08);
}

class AppSpacing { AppSpacing._();
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
  static const double screen = 16;
}

class AppRadius { AppRadius._();
  static const double sm = 4, md = 8, lg = 12, xl = 16, xxl = 24, pill = 999;
}
```

`AppTypography` defines `displayLarge … caption` (family: the app font; sizes
32→12). **Extend the scale — never inline a font size.** If a size isn't in the
scale, add it with a name.

## 3. Theming

`lib/app/core/theme/app_theme.dart` builds `AppTheme.light` and `AppTheme.dark`
from `ColorScheme.fromSeed(seedColor: AppColors.blue)` plus token overrides
(app bar, card, elevated button, input decoration, divider). `MaterialApp.router`
uses them and reads `themeMode` from a **`ThemeCubit`**.

Rules:
- Seed from brand blue; keep navy for headings/app bars.
- One `ThemeData` per brightness; components read `Theme.of(context)` — no
  hard-coded colours in widgets.
- Support system dark mode from day one.

## 4. Shared components

`lib/app/shared/widgets/` — generic, feature-agnostic only:

| Widget | Responsibility |
|--------|----------------|
| `AppScaffold` | Shell: app bar + body + optional bottom nav + offline banner |
| `AppButton` | Primary/secondary/outline/text variants, loading state, min 44×44 |
| `AppTextField` | Labelled input, validation, obscure toggle |
| `AppNetworkImage` | `cached_network_image` + shimmer placeholder + error widget |
| `AppCard` | Tokenised surface + multi-layer shadow |
| `AsyncView` | Maps a state to loading/empty/error/content |
| `EmptyState` | Icon + headline + description + CTA |
| `ErrorView` | Typed failure message + Retry |
| `OfflineBanner` | Connectivity / pending-sync indicator |
| `Skeleton` / `*Skeleton` | Shimmer placeholders shaped like the result |

**Rule:** a widget used by exactly one feature lives in
`features/<f>/presentation/widgets/`, never in `shared/`.

## 5. Aesthetics

- **Multi-layer shadows** for lift (one tight + dark, one wide + faint) — not a
  single heavy shadow.
- **Shimmer skeletons** shaped like the real content — not a centred spinner.
- **Clear size hierarchy** via `AppTypography`; don't invent intermediate sizes.
- **Icons** + text labels in nav; prefer `font_awesome_flutter`, fall back to
  Material for system actions.
- **Interactive feedback**: ripple / subtle elevation on press (glow), never a
  dead-looking tap.
- **Consistent spacing** from `AppSpacing`; **8 px grid** discipline.
- Optimistic UI must still *feel* responsive and show when it is submitting.

## 6. States: loading / empty / error

Every data screen owns all four. Never a blank screen.

| State | Show |
|-------|------|
| Loading (first) | Skeleton matching the layout |
| Empty | `EmptyState` — icon, headline, one-line explanation, CTA |
| Error | `ErrorView` — typed message (from `Failure`) + **Retry** |
| Refreshing | Keep content on screen + thin progress bar; show "Updated X ago" |

Distinguish **no data yet** from **nothing matches your filter** — different
copy, different action.

## 7. Accessibility

- Minimum **44 × 44** tap targets.
- `semanticLabel` on every meaningful icon/image.
- Contrast: **4.5:1** body text, **3:1** large text (WCAG AA).
- **Respect system text scaling** — test at the largest size; fix overflow, don't
  clip.
- Don't encode meaning in colour alone (status chips need a label/icon too).

## 8. Locale & content

- Currency is **BDT**; format via `intl`/`NumberFormat`. Never hand-format money.
- Dates/times: store UTC, display local, format via `intl` (`d MMM y`, `h:mm a`).
- Use `intl` (ARB) for user-facing strings when localisation begins; until then,
  keep strings in the widget layer (not buried in the bloc) so they're easy to
  extract. **Never** build user-facing text inside a datasource or use case.

## 9. Widget composition & screen size

**A screen file must never exceed 120 lines.** A screen is a *composition*, not a
dumping ground. Break the UI into small, single-purpose pieces and assemble them.

The rules:

1. **≤ 120 lines per screen file.** Over that, split it — no exceptions.
2. **Extract every visual block** (header, form, list row, footer, banner, empty
   state…) into its own widget file under
   `features/<feature>/presentation/widgets/`.
3. **Extracted widgets are `public`** (`class LoginForm`, not `_LoginForm`) so the
   screen imports and composes them — the state class may stay private.
4. **The screen imports them** and reads like a table of contents:
   ```dart
   Column(
     children: const <Widget>[
       LoginBranding(),
       SizedBox(height: AppSpacing.xxl),
       LoginForm(),
       SizedBox(height: AppSpacing.xxl),
       LoginFooter(),
     ],
   )
   ```
5. **One widget = one job.** If it needs two sentences to describe, split again.
6. **Feature-only widgets live in the feature's `widgets/`**; generic ones go to
   `app/shared/widgets/` (§4).
7. **The screen stays dumb**: no business logic, no formatting, no `setState` for
   data. Controllers/validation live in the extracted widget; state comes from the
   bloc (`context.watch` / `BlocBuilder`).
8. **Applies to every main screen** — auth, splash, dashboard, and every future
   feature screen. A long screen is a review blocker.

Why: small widgets are easier to read, test in isolation, reuse, and keep
rebuilds scoped (a small widget rebuilding doesn't repaint the whole screen) —
which is also what keeps us at [90–120 fps](performance.md).
