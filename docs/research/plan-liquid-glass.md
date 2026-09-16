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


## Phase 3, verified 2026-09-16 on a headless emulator

Checked on a Pixel 9 Pro AVD booted `-no-window` (1280x2856, dpr 3.0),
Impeller on the OpenGLES backend through ANGLE/SwiftShader. Headless because
both real devices on this machine were in use by other sessions; software
rendering is fine for *where* the refraction lands, and says nothing about
what it costs.

### The coordinate space, which the probe did not settle

The probe filtered the whole screen, where a filter-local coordinate and a
screen coordinate are the same number, so it could not tell which one
`FlutterFragCoord()` reports. Inside the bar's own box they differ, and the
answer is **screen space**: the panel's global rect, in device pixels, is
what the shader must be given.

Measured rather than assumed. Differencing a frosted frame against a liquid
one shows changed pixels beginning at x = 56, against a bar whose left edge
is at `margin 16 x dpr 3 = 48` — the first few columns being where the ramp
is still near zero.

### The band traces the shape

The difference map of `GlassyNavbarType.centered` is the pill's rim and
nothing else: both long edges, both rounded caps at the right radius, and a
black interior. The black interior is the early-out — pixels deeper than the
band really do cost one texture read.

`GlassyNavbarType.bottom` differs the way it should: the band follows the
top edge, curves at the two top corners, runs straight down the sides and
does not round at the bottom. That is the four-radii uniform doing its job;
one radius would have bent a curve into the two bottom corners, which are
square.

Both were checked with a non-zero `MediaQuery.padding` — the emulator's
gesture bar — and with the example's centre-docked button over the bar.

### Found while checking: the bar refracts its own border

The bright line along each edge in the difference maps is the panel's own
border, which `GlassyBottomNav` draws in the decoration *underneath* the
refraction layer, so the rim bends it along with the backdrop. Apple's glass
does the opposite: the rim highlight sits on top of the refraction, crisp.

Not a defect in the anchoring, and not fixed here — it belongs with Phase
4's specular rim, which has to decide what is drawn above the refraction
anyway. Worth knowing before that phase starts rather than rediscovering it.
