import 'package:flutter/widgets.dart';

/// How a `GlassyBottomNav` is shaped and positioned.
enum GlassyNavbarType {
  /// Docked to the bottom edge of the screen, spanning the full width with
  /// only the top corners rounded.
  bottom,

  /// A floating pill, inset from the bottom and the side edges and rounded on
  /// every corner.
  centered;

  /// The corner radius used for this type.
  ///
  /// [radius] overrides the default, which is 25 for [bottom] and 50 for
  /// [centered].
  BorderRadius resolveBorderRadius(double? radius) {
    switch (this) {
      case GlassyNavbarType.bottom:
        return BorderRadius.vertical(top: Radius.circular(radius ?? 25));
      case GlassyNavbarType.centered:
        return BorderRadius.circular(radius ?? 50);
    }
  }

  /// The space left around the bar when no margin is given.
  ///
  /// [bottom] sits flush against the screen edge, [centered] floats above it.
  EdgeInsets get defaultMargin {
    switch (this) {
      case GlassyNavbarType.bottom:
        return EdgeInsets.zero;
      case GlassyNavbarType.centered:
        return const EdgeInsets.only(bottom: 20, left: 16, right: 16);
    }
  }
}
