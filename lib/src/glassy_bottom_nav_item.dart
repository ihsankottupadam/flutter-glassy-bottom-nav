import 'package:flutter/widgets.dart';

/// A single destination in a `GlassyBottomNav`.
class GlassyBottomNavItem {
  /// The icon shown when the item is not selected, and also while it is
  /// selected if no [activeIcon] is given.
  final Widget icon;

  /// The icon shown while the item is selected.
  ///
  /// Falls back to [icon] when null.
  final Widget? activeIcon;

  /// The text under the icon, also used as the item's tooltip.
  final String label;

  /// Tints the marker above the icon and the background indicator while this
  /// item is selected.
  ///
  /// Falls back to the theme's `colorScheme.secondary`.
  final Color? activeColor;

  /// Creates a destination for a `GlassyBottomNav`.
  const GlassyBottomNavItem({
    required this.icon,
    required this.label,
    this.activeColor,
    this.activeIcon,
  });
}
