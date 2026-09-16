## 1.1.1

* Documentation only, with no change to the package's behaviour

## 1.1.0

* `glassStyle` adds `GlassStyle.liquid`, which keeps the frosted blur and
  refracts the backdrop along the bar's rim, with a lit edge over it
* The default is unchanged: a bar that does not ask for a style draws exactly
  the frosted bar it drew in 1.0.0
* `GlassStyle.liquid` needs the Impeller backend for its fragment shader. Where
  that is unavailable — the web, a Skia build — it resolves to
  `GlassStyle.frosted` rather than throwing, so it is safe to pass
  unconditionally
* `GlassStyle.resolved` reports which of the two a bar will actually draw here

### Fixed

* `GlassyNavbarType.bottom` no longer draws its labels inside the
  home-indicator zone. The bar takes the display's bottom inset into account,
  and `GlassyNavbarType.centered` grows past its own 20px margin when a
  display asks for more. An explicit `margin` is still used exactly as given
* The background indicator is positioned directionally, so under
  `TextDirection.rtl` it highlights the selected item instead of its mirror
  image
* Each destination is now one semantics node, announced as a selected or
  unselected button in a mutually exclusive group, and activatable from a
  screen reader. The label is no longer read more than once

## 1.0.0

* Initial release of `GlassyBottomNav`, a frosted-glass bottom navigation bar
* `GlassyNavbarType.bottom` docks the bar to the bottom edge,
  `GlassyNavbarType.centered` floats it as a pill
* Animated background indicator and marker, both tinted by the selected item's
  `activeColor`
* Optional `currentIndex` for driving the selection from a `PageController`, a
  router or your own state
* `labelStyle` and `selectedLabelStyle`, with `showSelectedLabel` and
  `showUnselectedLabel` controlling which labels appear
* Configurable `backgroundBlur`, `backgroundColor`, `borderThickness`,
  `borderColor`, `borderRadius`, `margin`, `padding`, `markerSize` and
  `duration`
