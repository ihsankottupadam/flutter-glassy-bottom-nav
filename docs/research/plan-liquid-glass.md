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


## Phase 4, the look, tuned 2026-09-16 on the same headless emulator

Same Pixel 9 Pro AVD, `-no-window`, Impeller on OpenGLES through
ANGLE/SwiftShader. Software rendering says nothing about cost, but it
renders the right pixels, which is all the look needs. Every frame below is
the example's **Favorites** tab, whose grid of large gradient tiles is the
only place in the example with real contrast directly behind the bar — the
Discover tab's backdrop there is near-flat dark, where the refraction is
invisible whatever it is set to, and tuning against it would have been
tuning against nothing.

### What a layer above the blur costs: the bar's own contents

The first device look at Phase 3's output showed the selection marker
**gone**. It sits about 8 logical px below the bar's top edge, inside a 14px
rim band, so the refraction displaced it past the edge and replaced it with
what was deeper in. The border was refracted into a second ghost outline
inside the real one, the finding left open at the end of Phase 3.

`ImageFilter.compose(outer: shader, inner: blur)` on the bar's existing
`BackdropFilter` fixes both at once, and it is what ships. Marker, icons,
labels and border are the filter's child and stay crisp; only the backdrop
bends. The plan's `## Declined` entry against `compose` was measured with a
full-screen inner blur and does not apply to a blur already clipped to the
panel.

### The direction of the bend

Sampling *outward* — `frag + d * normal`, the physically right direction for
a glass bevel, pulling the surroundings in — genuinely works: the `4:21`
beside the bar becomes legible as `5:21` squeezed into the rim. It also
fringes: the sample leaves the filter's input, which stops at the
`ClipRRect`, and a green halo spills past the outline. Inward it is, so the
rim magnifies the interior rather than squeezing in the exterior. A filter
wider than the bar would be needed for the real thing, and a widget in
`Scaffold.bottomNavigationBar` has no way to paint outside its own box.

### Band, amount and rim

Six builds, judged side by side over the same artwork, band and amount in
logical px:

| variant | band | amount | rim w/opacity | reads as |
|---|---|---|---|---|
| A | 14 | 12 | 1.5 / 0.5 | inflated; the caps pillow out |
| **B** | **12** | **8** | **1.5 / 0.5** | **shipped** — a bevel, with the tile boundary visibly pinched at the rim |
| C | 10 | 5 | 1.5 / 0.5 | near-indistinguishable from frosted |
| F | 12 | 8 | 2.5 / 0.8 | a chunky white stroke, not light on an edge |
| G | 12 | 8 | 1.0 / 0.3 | rim all but absent |
| E | 14 | 12 | 1.5 / 0.5, outward | see above; fringes past the clip |

The band is clamped in the shader to half the bar's shortest half-axis so a
short bar narrows its rim rather than having the two bevels meet in the
middle, and the travel shrinks with it.

### Whether the rim needs the blur moved into the shader

No, and the evidence is one pair of frames. Dropping the example's
`backgroundBlur` from 22 to 6 and changing nothing else makes the rim bend
recognisable content and reads markedly closer to iOS; at 22 the same rim is
a plain soft bevel. So rim sharpness tracks `backgroundBlur`, which is the
caller's knob, and the package's default of 10 sits at the sharp end. The
in-shader blur stays in reserve for the one case the two layers cannot
serve: a caller who wants a heavy blur *and* a crisp rim.

### Why no new parameters

Band, amount, rim width and rim opacity are all kept private. They were
tuned as a set and only read as glass in combination — F and G above are
each one knob away from B and each looks wrong. The knob that genuinely
changes how the rim reads is `backgroundBlur`, which already exists. Adding
a parameter in 1.2.0 is not a breaking change; removing one is.
