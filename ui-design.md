# UI & Design System

The architecture keeps the code maintainable; the UI keeps it usable. Pull every value from tokens rather than inlining magic numbers.

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

Use extensions everywhere: `.w`, `.h`, `.sp`, `.r`.

## 2. Design tokens

`lib/app/core/theme/design_system.dart` should hold your app’s single source of truth.

```dart
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);
}
```

Use a naming system that matches the product; avoid hard-coded colors in widgets.

## 3. Theming

Use `ThemeData` built from a small number of tokens, with a dark mode variant as needed.

Rules:
- One `ThemeData` per brightness.
- Components read `Theme.of(context)`.
- Support dark mode from day one.

## 4. Shared components

`lib/app/shared/widgets/` — generic, feature-agnostic components only.

Use: `AppScaffold`, `AppButton`, `AppTextField`, `AppNetworkImage`, `AppCard`, `AsyncView`, `EmptyState`, `ErrorView`, `Skeleton`.

## 5. Aesthetics

- Use tokenized spacing and radius values.
- Keep visual hierarchy clear.
- Use subtle elevation and consistent interaction states.
- Prefer clean, readable layouts over over-designed interfaces.

## 6. States: loading / empty / error

Every data screen should support all four states.

| State | Show |
|-------|------|
| Loading | Skeleton matching layout |
| Empty | EmptyState with explanation and CTA |
| Error | ErrorView with Retry |
| Refreshing | Keep content visible with a subtle progress indicator |

## 7. Accessibility

- Minimum **44 × 44** tap targets.
- Contrast should be safe for normal and large text.
- Respect system text scaling.
- Add `semanticLabel`s to meaningful icons/images.

## 8. Locale & content

- Use `intl` for dates, money, and numbers.
- Keep user-facing strings in the UI layer, not buried in data or domain code.
- Support localization when the product requires it.

## 9. Widget composition & screen size

**A screen file must not exceed 120 lines.** A screen is a composition of smaller widgets.

The rules:

1. Split large screens into extracted public widgets.
2. Keep one widget = one job.
3. Feature-specific widgets are under the feature; generic ones go to `app/shared/widgets/`.
4. Screen files stay thin and readable.
