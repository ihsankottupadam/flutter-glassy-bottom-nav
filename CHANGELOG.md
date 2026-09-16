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
