A glass bottom navigation bar, frosted or liquid, with an animated selection
indicator, per-item active colours and two layouts.

<table>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/main/screenshots/centered.png" width="250" alt="The bar floating as a pill above the bottom edge"></td>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/main/screenshots/bottom.png" width="250" alt="The bar docked to the bottom edge"></td>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/main/screenshots/docked_button.png" width="250" alt="A center-docked action button over the bar on the Books destination"></td>
  </tr>
  <tr>
    <td align="center"><code>GlassyNavbarType.centered</code><br>a floating pill</td>
    <td align="center"><code>GlassyNavbarType.bottom</code><br>docked to the edge</td>
    <td align="center">with a <code>centerDocked</code><br>action button</td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/main/screenshots/liquid.png" width="250" alt="The liquid glass style, bending the artwork behind the bar along its rim"></td>
  </tr>
  <tr>
    <td align="center"><code>GlassStyle.liquid</code><br>the rim bends what is behind it</td>
  </tr>
</table>

## Features

* Frosted glass — blurs whatever scrolls behind it, with a configurable sigma
* Liquid glass — the same blur, with the rim refracting the backdrop and
  catching light, falling back to frosted where it cannot run
* Animated background indicator that slides to the selected item
* Animated marker above the selected icon
* Per-item active colour, tinting both the indicator and the marker
* Separate icon for the selected state
* Two layouts: docked to the bottom edge, or a floating pill
* Labels on the selected item, the unselected items, both or neither
* Styleable labels, with a separate style for the selected one
* Self-tracking or fully controlled by the parent, for a `PageController` or a
  router
* Configurable blur, tint, border, corner radius, margin, padding, marker size
  and animation duration

## Usage

The bar blurs what is painted behind it, so put it in a `Scaffold` with
`extendBody: true`:

```dart
Scaffold(
  extendBody: true,
  body: const MyPage(),
  bottomNavigationBar: GlassyBottomNav(
    onChange: (index) => setState(() => _index = index),
    items: [
      GlassyBottomNavItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: 'Home',
        activeColor: Colors.green,
      ),
      GlassyBottomNavItem(
        icon: const Icon(Icons.favorite_border),
        activeIcon: const Icon(Icons.favorite),
        label: 'Favorite',
        activeColor: Colors.red,
      ),
    ],
  ),
)
```

Without `activeColor` an item falls back to the theme's
`colorScheme.secondary`.

## Layouts

`navbarType` picks the shape. `GlassyNavbarType.centered` (the default) floats
the bar as a pill, inset from the bottom and the sides:

```dart
GlassyBottomNav(
  navbarType: GlassyNavbarType.centered,
  items: items,
)
```

`GlassyNavbarType.bottom` docks it to the bottom edge, spanning the full width
with only the top corners rounded:

```dart
GlassyBottomNav(
  navbarType: GlassyNavbarType.bottom,
  items: items,
)
```

Either can be overridden with `margin` and `borderRadius`.

## Controlled selection

By default the bar tracks the selection itself, starting at `initialIndex`.
Pass `currentIndex` when something else owns the current page — a
`PageController`, a router, or your own state. Taps then only report through
`onChange`, and the bar moves when you pass a new `currentIndex`:

```dart
GlassyBottomNav(
  currentIndex: _index,
  onChange: (index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  },
  items: items,
)
```

## Glass styles

`glassStyle` picks how the bar treats what is behind it.
`GlassStyle.frosted` is the default and the blur the bar has always drawn.
`GlassStyle.liquid` keeps that blur and bends the backdrop along the bar's
edge, with a lit rim:

```dart
GlassyBottomNav(
  glassStyle: GlassStyle.liquid,
  items: items,
)
```

That is the whole API. There is nothing to await, no capability to check and
no second widget to swap in.

**It needs Impeller.** The refraction is a fragment shader, and
`ui.ImageFilter.shader` only exists on Impeller — so not on the web, and not
in a build still running Skia. Asking for `liquid` there is not an error and
does not throw: the bar resolves it to `frosted` and draws that instead. The
fallback is not something you arrange, it is what this package already
draws, so `glassStyle: GlassStyle.liquid` is safe to write unconditionally
in an app that also ships to the web.

To find out which one you will get before building a bar — to word a
settings screen, say — ask the style itself:

```dart
if (GlassStyle.liquid.resolved == GlassStyle.liquid) {
  // The shader will run here.
}
```

Two things worth knowing about how it looks:

* **`backgroundBlur` is the control over the rim.** What the rim bends is
  the blurred backdrop, so a low sigma leaves the bent content recognisable
  through the edge and a high one softens the rim into a plain bevel. The
  default of `10` sits at the sharp end.
* **The bar's own contents are painted on the glass, not through it.** Icons,
  labels, the marker and the border stay crisp whatever the backdrop is
  doing.

The rim has no settings of its own. Band width, refraction distance and the
highlight were tuned as a set and only read as glass in combination.

### What it costs

Measured on a Redmi 13 5G (Snapdragon 4 Gen 2) at 60 Hz, a profile build,
with the content behind the bar repainting every single frame — the worst
case, since nothing can be cached:

| | GPU raster per frame |
| --- | --- |
| no filter behind the bar | 7.2 ms |
| `GlassStyle.frosted` | 17.0 ms |
| `GlassStyle.liquid` | 19.9 ms |

**The blur is the expensive part, not the refraction.** Liquid adds 17% on
top of frosted; frosted adds nearly ten milliseconds over drawing no glass
at all. If a bar is too expensive on a device, the first thing to reach for
is a lower `backgroundBlur`, not a different `glassStyle`.

Those are ceilings, not typical frames. An app whose content behind the bar
is still — most apps, most of the time — lets the raster cache keep the
filtered layer and pays this only while something scrolls.

There is no device-tier check inside the package, deliberately: it would be
gating the cheap part of the cost. `glassStyle` is an ordinary parameter, so
an app that wants to make that call can wire it to its own quality setting.

## Styling the glass

```dart
GlassyBottomNav(
  backgroundBlur: 20,
  backgroundColor: Colors.black,
  borderThickness: 0.5,
  borderColor: Colors.white.withValues(alpha: 0.15),
  showUnselectedLabel: false,
  labelStyle: const TextStyle(fontSize: 11),
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
  markerSize: const Size(24, 3),
  duration: const Duration(milliseconds: 250),
  items: items,
)
```

## GlassyBottomNav

| Parameter | Default | Description |
| --- | --- | --- |
| `items` | required | The destinations, laid out with equal widths |
| `initialIndex` | `0` | The index selected on first build |
| `currentIndex` | `null` | Set it to drive the selection from outside |
| `onChange` | `null` | Called with the new index when a different item is tapped |
| `navbarType` | `centered` | Floating pill, or docked to the bottom edge |
| `glassStyle` | `frosted` | `liquid` refracts the rim where Impeller can run it |
| `showBackgroundIndicator` | `true` | Tinted panel behind the selected item |
| `backgroundBlur` | `10` | Blur sigma applied to the backdrop |
| `backgroundColor` | `null` | Tints the glass, at 10% opacity |
| `borderRadius` | type default | 25 for `bottom`, 50 for `centered` |
| `borderThickness` | `null` | No border is drawn when null |
| `borderColor` | translucent white | Ignored unless `borderThickness` is set |
| `margin` | type default | Space around the bar |
| `padding` | `EdgeInsets.zero` | Space between the bar's edges and its items |
| `showSelectedLabel` | `true` | Label under the selected icon |
| `showUnselectedLabel` | `true` | Labels under the other icons |
| `labelStyle` | white 12px | Merged over the default label style |
| `selectedLabelStyle` | `null` | Merged over `labelStyle` when selected |
| `markerSize` | `Size(20, 3)` | Marker above the selected icon |
| `duration` | 150ms | Indicator and marker animation |

## GlassyBottomNavItem

| Parameter | Default | Description |
| --- | --- | --- |
| `icon` | required | Shown while the item is not selected |
| `activeIcon` | `icon` | Shown while the item is selected |
| `label` | required | Text under the icon, and the item's tooltip |
| `activeColor` | `colorScheme.secondary` | Tints the marker and the indicator |

## Example

See [`example/`](example) for a four-destination app that drives the bar from
a `PageController`. Its header has two switches: one flips between the layouts,
the other docks a `FloatingActionButtonLocation.centerDocked` button over the
bar, which works with either layout.
