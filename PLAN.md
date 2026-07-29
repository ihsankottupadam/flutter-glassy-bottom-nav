# PLAN — glassy_bottom_nav

Turn the `GlassyBottomNav` widget from the demo app
(`flutter-glassy-bottom-nav`) into a publishable Flutter package, following the
same layout and conventions as `gradient_slider`.

## Goal

A frosted-glass bottom navigation bar: a `BackdropFilter` blurred bar with an
animated selection indicator, optional labels, per-item active colours and two
layouts (docked to the bottom edge, or a floating pill).

## Source

`../../flutter-glassy-bottom-nav/lib/bottom_nav/glassy_bottom_nav.dart` — a
single-file widget written as app code. It is not package-ready:

- `labelStyle` is accepted but never applied (the item hardcodes white text).
- `activeColor` falls back to a hardcoded `Colors.green` for the top marker but
  to `Theme.of(context).colorScheme.secondary` for the indicator.
- No way to drive the selected index from the parent — the widget owns its
  state, so it cannot follow an external `PageController`/router.
- `withOpacity` is deprecated in current Flutter.
- No docs, no tests, no example.

## Steps

1. **Scaffold** — empty `flutter create --template=package` repo + this plan.
2. **Port the widget** into `lib/src/`, exported from
   `lib/glassy_bottom_nav.dart`:
   - `GlassyBottomNav` — the bar.
   - `GlassyBottomNavItem` — icon, optional active icon, label, active colour.
   - `GlassyNavbarType` — `bottom` (edge-docked, top corners rounded) and
     `centered` (floating pill with margin).
3. **Fix the API** while porting:
   - Apply `labelStyle`, and add `selectedLabelStyle` for the active item.
   - Optional `currentIndex` so the bar can be fully controlled; internal state
     is only used when it is null.
   - Single `activeColor` resolution shared by the indicator and the marker,
     falling back to the theme.
   - Replace `withOpacity` with `withValues(alpha:)`.
   - Expose the animation `duration` and the indicator/marker sizing instead of
     hardcoding 150ms / 20x3.
4. **Example app** (`example/`) — port the demo screen, showing both navbar
   types over a background image.
5. **Tests** (`test/`) — taps change selection and fire `onChange`, controlled
   mode ignores internal state, labels honour the show flags, indicator only
   renders when enabled, both navbar types lay out.
6. **Docs & metadata** — README with usage and a parameter table, CHANGELOG,
   LICENSE, pubspec metadata (description, topics, repo links), screenshot.
7. **CI** — GitHub Actions running format, analyze and test for both the
   package and the example.

## Conventions

- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`, `build:`).
- `package:lints/recommended.yaml`, `dart format` clean.
- Public API documented with `///` comments.
