A frosted-glass bottom navigation bar, with an animated selection indicator,
per-item active colours and two layouts.

<table>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/master/screenshots/centered.png" width="250" alt="The bar floating as a pill above the bottom edge"></td>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/master/screenshots/bottom.png" width="250" alt="The bar docked to the bottom edge"></td>
    <td align="center"><img src="https://raw.githubusercontent.com/ihsankottupadam/flutter-glassy-bottom-nav/master/screenshots/docked_button.png" width="250" alt="A center-docked action button over the bar on the Books destination"></td>
  </tr>
  <tr>
    <td align="center"><code>GlassyNavbarType.centered</code><br>a floating pill</td>
    <td align="center"><code>GlassyNavbarType.bottom</code><br>docked to the edge</td>
    <td align="center">with a <code>centerDocked</code><br>action button</td>
  </tr>
</table>

## Features

* Frosted glass — blurs whatever scrolls behind it, with a configurable sigma
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
