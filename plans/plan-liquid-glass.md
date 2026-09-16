# the bar refracts its backdrop where the GPU allows, and frosts where it does not

## The ask

"What about adding the support to ios liquid glass style in this package" —
then, when the first answer was to build it elsewhere, the correction that
settled the scope: "my package provides a new style of bottom nav so adding
liquid glass style worth it".

That is the right framing and it decides the shape. This package's identity
*is* the glass look, and `navbarType` already establishes a style axis, so
liquid glass belongs on the axis rather than in a second package. A
frosted-only glass bar reads as pre-iOS-26, and someone searching for a
glass bottom nav will increasingly expect the liquid one.

It lands after 1.0.1. The three correctness fixes in `PLAN.md` — the bottom
safe-area inset, the right-to-left indicator, the semantics — are bugs in
code people are running now, and this is a new style nobody is missing yet.
The prototype is what makes that ordering safe rather than a guess: the
feature turned out small and cheap, so it does not need to jump the queue to
be de-risked early.

## The decision

A `GlassStyle` on the widget, `frosted` (what ships) and `liquid`, with
`frosted` the default so no 1.x caller changes behaviour.

The liquid style is **additive**: today's drawing is untouched and becomes
the lower of two layers.

- **Inner** — the bar-sized `ClipRRect` + `BackdropFilter(ImageFilter.blur)`
  already at `lib/src/glassy_bottom_nav.dart:207`, unchanged.
- **Outer** — a second, *full-screen* `BackdropFilter` holding
  `ui.ImageFilter.shader`, above the first, so its input already contains
  the blurred bar and the rim refracts blurred content, which is what liquid
  glass actually looks like.

The shader is handed the whole screen and masks itself: it takes the bar's
rect as a uniform in `FlutterFragCoord()`'s device-pixel space, computes a
rounded-rect SDF, bends only a band inside the rim, and returns a single
passthrough sample everywhere else. That is why a full-screen pass is
affordable, and why no capture of the backdrop is needed. `docs/research/
plan-liquid-glass.md` has the measurements and the competitor claim this
contradicts.

`ui.ImageFilter.shader` needs Impeller, so `liquid` resolves to `frosted`
wherever `ui.ImageFilter.isShaderFilterSupported` is false — the web, a
Skia build. The fallback costs nothing to design because this package
already ships it as its main product, which is the structural reason the
style belongs here rather than in a package that would have to invent one.

## Declined

- **Apple's `UIGlassEffect` in a platform view**, as `real_liquid_glass` and
  `fresnel` do. Better on iOS 26+, and it turns a pure-Dart widget package
  into a plugin with an iOS build directory, a platform interface and an
  Xcode 26 requirement. `COMPETITORS.md` ruled this out before the prototype
  and the prototype does not reopen it.
- **Depending on `liquid_glass_renderer`.** It is `0.2.0-dev.4` and says not
  to use it in production; a stable package cannot sensibly take a
  prerelease constraint.
- **Vendoring it**, as `liquid_glass_bottom_nav` does — ~5,300 copied lines
  into a package whose entire `lib` is 407.
- **`ImageFilter.compose(outer: shader, inner: blur)`**, one filter instead
  of two layers. A full-screen inner blur blurs the whole screen and the
  shader has no unblurred input to restore it from. Measured, not reasoned.
- **The capture architecture** — `OffsetLayer.toImageSync` of the source per
  frame, which `fluid_glass` needs for its general case. A sliding indicator
  over glass is the worst possible host for a per-frame pipeline flush, and
  the uniform-anchoring result means it is not required here.
- **A device-tier classifier**, as `fluid_glass` carries. It exists to
  decide when refraction is affordable; the measurements say it is close to
  free, so the capability check alone is enough until a device says
  otherwise.
- **Chromatic dispersion.** Seven texture samples instead of one for a
  prism fringe at the rim. Cheap to add later behind a flag; not in the
  first cut.

**Held in reserve, not declined: moving the blur into the shader.** The two
layers blur first and refract second, so the rim bends content that is
already blurred. Both reference implementations do it that way — the filter
shader in `liquid_glass_renderer` takes its input as `uBlurredTexture`, and
`fluid_glass`'s `lens()` describes itself as following "a preceding blur" —
so it is the established order and it is what the first cut builds.

It is not quite what Apple draws. iOS's rim carries a brighter, sharper band
that reads as recognisable content seen through thick glass, which a rim
sampling only blurred pixels cannot produce. If Phase 4's tuning leaves the
edge looking mushy rather than glassy, that is the cause, and the fix is a
single pass that does both: the shader blurs the interior with its own
multi-tap and samples sharper content at the rim, instead of receiving a
blurred texture. It costs more than the current early-out and the
measurements say there is headroom for it.

Not built speculatively — the cheaper ingredients (band, amount, the
specular highlight) may be enough, and this is the thing to reach for if
they are not.

## What the tests hold

`flutter_test` runs on Skia, where `ui.ImageFilter.shader` throws rather
than constructing, so the shader path itself cannot be exercised by this
suite. What can be pinned, and is worth more:

- `GlassStyle.liquid` resolves to `frosted` when the backend cannot run
  runtime shaders — which under `flutter_test` is always, making the
  fallback the one path the suite covers completely.
- The frosted tree is unchanged by the new parameter: a `GlassyBottomNav`
  with no `glassStyle` builds the same widget tree it did at 1.0.0.
- The existing 507 lines of tests keep passing untouched, which is the
  claim that this is additive.

## Phases

### Phase 1: the style axis

- [ ] Add `GlassStyle` with `frosted` and `liquid` in
  `lib/src/glass_style.dart`, dartdoc'd for what each draws and what
  `liquid` needs, and export it from `lib/glassy_bottom_nav.dart`.
- [ ] Add a `glassStyle` parameter to `GlassyBottomNav` defaulting to
  `GlassStyle.frosted`, so no existing caller changes behaviour.
- [ ] Resolve the effective style in one private helper that returns
  `frosted` whenever `ui.ImageFilter.isShaderFilterSupported` is false, so
  every later phase reads the resolved value rather than the parameter.
- [ ] Add `test/glass_style_test.dart` asserting that `liquid` resolves to
  `frosted` under `flutter_test`, and that a bar built without
  `glassStyle` produces the tree it produced before this phase.

### Phase 2: the shader asset

- [ ] Add `lib/src/shaders/liquid_glass.frag`: the rounded-rect SDF, the
  outward normal from its gradient, a rim band with the quarter-circle
  ramp, an early-out returning one passthrough sample outside the shape and
  inside the band's inner limit.
- [ ] Declare it under `flutter: shaders:` in the package's `pubspec.yaml`
  and confirm it compiles by running the example, not by inspection.
- [ ] Load it with `FragmentProgram.fromAsset` under the package-qualified
  key `packages/glassy_bottom_nav/lib/src/shaders/liquid_glass.frag`, the
  spelling a package asset needs and the usual trap.
- [ ] Hold the loaded program in a library-level cache so several bars, or
  a bar rebuilt, compile it once; render frosted until the future resolves
  rather than dropping a frame.

### Phase 3: the second layer

- [ ] Give the bar a way to know its own global rect in logical pixels,
  measured from its `RenderBox` rather than recomputed from margins, so the
  uniform survives a caller's custom `margin` and `borderRadius`.
- [ ] Paint the full-screen `BackdropFilter(ui.ImageFilter.shader)` above
  the existing blur when the resolved style is `liquid`, with the bar's
  rect, corner radius, band width and amount set as uniforms in device
  pixels.
- [ ] Build nothing extra when the resolved style is `frosted`, so the
  frosted widget tree stays exactly as Phase 1 pinned it.
- [ ] Check the bar still refracts correctly under a non-zero
  `MediaQuery.padding`, in `GlassyNavbarType.bottom` as well as `centered`,
  and with the example's centre-docked button over it.

### Phase 4: the look

- [ ] Tune band width and amount against the example until the rim reads as
  glass rather than as a fisheye; the prototype's 18 and 22 are a starting
  point and are visibly too strong.
- [ ] Add the specular rim highlight, without which the refraction reads as
  a distortion rather than as an edge catching light.
- [ ] Expose whichever of those the caller needs and no more, defaulting to
  the tuned values, and say in the dartdoc what each does.
- [ ] Judge the rim against iOS's own glass once band, amount and the
  highlight are tuned, and record in this plan's `## Declined` whether the
  in-shader blur held in reserve there is needed or the two layers suffice.
- [ ] Add a `screenshots/liquid.png` showing the style over the example's
  artwork, and list it in `pubspec.yaml`'s `screenshots:`.

### Phase 5: the numbers and the release

- [ ] Re-run the four-mode comparison as a `--profile` build on the Android
  handset, several samples per mode so variance is measured rather than
  inferred, and replace the macOS table in
  `docs/research/plan-liquid-glass.md` with it.
- [ ] Decide from those numbers whether the capability check is enough or
  whether a device opt-out is needed, and record the answer in this plan's
  `## Declined` beside the classifier entry.
- [ ] Document the style in `README.md`, saying plainly that it needs
  Impeller and falls back to frosted on the web.
- [ ] Add the `CHANGELOG.md` entry and bump `pubspec.yaml` to 1.1.0, noting
  that the default is unchanged.
