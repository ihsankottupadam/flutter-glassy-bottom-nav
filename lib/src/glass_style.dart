import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// How a `GlassyBottomNav` treats what is painted behind it.
enum GlassStyle {
  /// Blurs the backdrop behind the bar.
  ///
  /// Works on every platform Flutter runs on, and is the default.
  frosted,

  /// Blurs the backdrop and bends it along the bar's edge.
  ///
  /// The blur is the same one [frosted] draws; the refraction is a fragment
  /// shader over the rim, which reads as a piece of glass thick enough to
  /// have a lens at its edge.
  ///
  /// The shader needs the Impeller rendering backend, so this is not
  /// available everywhere — notably not on the web. Asking for it where it
  /// cannot run is not an error: it resolves to [frosted], which is what
  /// [GlassStyleResolution.resolved] reports and what the bar then draws.
  liquid,
}

/// What a [GlassStyle] turns into on the backend actually in use.
extension GlassStyleResolution on GlassStyle {
  /// The style that will really be drawn here.
  ///
  /// [GlassStyle.liquid] becomes [GlassStyle.frosted] wherever
  /// [ui.ImageFilter.shader] cannot be constructed, which is every backend
  /// but Impeller. Read it to find out what a bar will look like before
  /// building one — to word a settings screen, say. Nothing needs to be
  /// checked before passing [GlassStyle.liquid] to the bar itself, which
  /// resolves it the same way.
  GlassStyle get resolved =>
      resolveFor(shadersSupported: ui.ImageFilter.isShaderFilterSupported);

  /// [resolved], with the backend's capability passed in rather than read.
  ///
  /// `flutter_test` runs on Skia, where [ui.ImageFilter.shader] throws
  /// rather than being constructed, so [ui.ImageFilter.isShaderFilterSupported]
  /// is always false under test and a test reading it could only ever reach
  /// one of the two branches. Supplying the capability is what makes both
  /// reachable.
  @visibleForTesting
  GlassStyle resolveFor({required bool shadersSupported}) =>
      this == GlassStyle.liquid && shadersSupported
          ? GlassStyle.liquid
          : GlassStyle.frosted;
}
