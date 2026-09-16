# Evidence behind `plans/plan-liquid-glass.md`

Measured 2026-09-16. Kept because the plan's shape rests on two numbers and
one negative result, and none of them is obvious from reading the code.

The probe that produced these lives at `example/lib/probe_main.dart` and
`example/shaders/liquid_glass_probe.frag`:

    flutter run -t lib/probe_main.dart

## Can the refraction be anchored without capturing the backdrop?

Yes. This is the finding the whole design rests on.

`fluid_glass` 0.1.17 rejects the plain-`BackdropFilter` route, in
`lib/src/draw_backdrop.dart:770`:

> a fragment shader in a backdrop filter is handed the whole screen rather
> than the element's texture, so the lens would have nothing to anchor its
> geometry to

The first clause is true and the conclusion does not follow: the geometry
does not have to come *from* the texture. Passing the bar's rect in as a
uniform, in the same device-pixel space as `FlutterFragCoord()`, anchors it
exactly — a debug mode painting the SDF band traced the pill's rounded rect
to the pixel, at the right position and the right corner radius, on a
full-screen backdrop input.

So the shader is handed the whole screen and **masks itself**: every pixel
outside the SDF is one passthrough texture read. That is what removes the
need for `OffsetLayer.toImageSync`, which the same file calls
(`draw_backdrop.dart:757`) "by a wide margin the most expensive thing here"
and which "dropping the refraction does nothing about".

## What it costs

Rolling mean of 60 frames' raster time, animated backdrop repainting every
frame, one app launch per mode, slider values verified unchanged at
18 / 22 / 22 in all four captures.

| mode | raster | what it is |
| --- | --- | --- |
| none | 0.42 ms | floor: no filter at all |
| blur | 0.70 ms | bar-sized clipped blur — what ships today |
| liquid | 0.44 ms | full-screen refraction shader, no blur |
| stacked | 0.66 ms | both: today's blur with the shader above it |

- The refraction is not the expensive part; the blur is. The shader alone
  costs +0.02 ms over an unfiltered frame, the blur alone +0.28 ms. The
  early-out is doing its job.
- Stacking the shader onto the blur is free within noise. `stacked` came
  out *below* `blur`, which cannot be real — so run-to-run variance is at
  least ±0.05 ms and the shader's true added cost is inside it.

**What these numbers are not.** n=1 per mode, debug build, macOS, an
800x632 window on a Mac GPU. They establish the shape of the cost, not its
magnitude on a phone. Phase 5 replaces them.

## Negative result: the two filters cannot be composed

`ui.ImageFilter.compose(outer: shader, inner: blur)` does not work for this.
The blur would be the inner stage of a full-screen filter, so it blurs the
whole screen, and the shader has no unblurred input left to restore the
rest of the screen from. Two stacked `BackdropFilter`s — a bar-sized blur
with a full-screen shader above it — is what makes the masking correct.

## What the alternatives cost

- `liquid_glass_renderer` 0.2.0-dev.4 is the mature shader implementation:
  24,442 downloads/30d, 886 likes, and a README that still opens
  "EXPERIMENTAL - USE WITH CAUTION ... should not be blindly added to
  production apps". Impeller only; memory spikes from flutter#138627 when
  shapes animate.
- `liquid_glass_bottom_nav` 0.0.14 is 5,608 lines, of which ~5,300 are that
  package vendored byte-for-byte into `lib/src/liquid_glass_renderer/`,
  which is what depending on a `-dev` prerelease costs. Its own bar is
  ~300 lines. This package is 407 lines of `lib` and 507 of tests.
- `real_liquid_glass` 0.3.0 hosts Apple's `UIGlassEffect` in a platform
  view. Genuinely better on iOS 26+, and it requires building with
  Xcode 26+ and an iOS half this package does not have.
