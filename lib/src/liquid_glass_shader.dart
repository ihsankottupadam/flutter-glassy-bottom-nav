import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// The compiled rim-refraction program, shared by every bar in the app.
///
/// Compiling a fragment program is asynchronous and not free, and a bar that
/// compiled its own would pay for it again on every rebuild, so the result is
/// held here rather than in any one [State].
///
/// Nothing loads until a bar actually resolves to `GlassStyle.liquid`: a bar
/// that stays frosted, and every app on a backend that cannot run the shader
/// at all, never touches the asset.
abstract final class LiquidGlassShader {
  /// The asset key, which is not quite the path in `pubspec.yaml`.
  ///
  /// A package's shader is addressed as `packages/<package>/<declared path>`,
  /// and unlike an ordinary package asset the `lib/` stays in — it is part of
  /// the declared path, not an implied root.
  ///
  /// One caveat for anyone writing a test that forces the liquid style:
  /// under `flutter_test` the bundle drops the `packages/<package>/` prefix
  /// and the key is the bare declared path. Nothing here special-cases that,
  /// because detecting a test run needs `dart:io` and this package supports
  /// the web. It does not arise in practice — `flutter_test` runs on Skia,
  /// where the style resolves to frosted and this is never reached.
  static const String assetKey =
      'packages/glassy_bottom_nav/lib/src/shaders/liquid_glass.frag';

  static ui.FragmentProgram? _program;
  static Future<void>? _loading;
  static bool _failed = false;

  /// The program, or null while it is still compiling or if it could not be.
  ///
  /// A caller that gets null draws the frosted bar for that frame rather than
  /// waiting, so the first frames of an app are never held up by a shader.
  static ui.FragmentProgram? get program => _program;

  /// Whether loading was tried and did not work.
  ///
  /// Once true the bar stays frosted for the rest of the session instead of
  /// retrying an asset that is not going to appear.
  static bool get failed => _failed;

  /// Compiles the program if it is not compiled already.
  ///
  /// Idempotent and safe to call from `build`: concurrent callers share one
  /// future, and a finished or failed load returns immediately.
  static Future<void> load() {
    if (_program != null || _failed) return Future<void>.value();
    return _loading ??= ui.FragmentProgram.fromAsset(assetKey).then(
      (ui.FragmentProgram program) {
        _program = program;
        _loading = null;
      },
      onError: (Object error, StackTrace stackTrace) {
        _failed = true;
        _loading = null;
        // Not rethrown: a missing or uncompilable shader costs the app its
        // rim refraction, not its navigation bar.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'glassy_bottom_nav',
            context: ErrorDescription(
              'while loading the GlassStyle.liquid shader; the bar will draw '
              'GlassStyle.frosted instead',
            ),
          ),
        );
      },
    );
  }

  /// Forgets what was loaded, so a test can exercise the load again.
  @visibleForTesting
  static void debugReset() {
    _program = null;
    _loading = null;
    _failed = false;
  }
}
