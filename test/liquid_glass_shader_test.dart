import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/src/liquid_glass_shader.dart';

/// The key without the `packages/<package>/` prefix.
///
/// What the asset is called inside a `flutter test` bundle, and the reason
/// [LiquidGlassShader.assetKey] cannot be used as-is from a test.
const String _keyUnderTest = 'lib/src/shaders/liquid_glass.frag';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(LiquidGlassShader.debugReset);
  tearDown(LiquidGlassShader.debugReset);

  test('the shader compiles and can be loaded', () async {
    // The claim that matters most here: the GLSL is valid and impellerc
    // turned it into something dart:ui will accept. A syntax error in the
    // shader fails this, which is otherwise only visible when running an
    // app on a device.
    final program = await ui.FragmentProgram.fromAsset(_keyUnderTest);

    expect(program, isNotNull);
  });

  test('the shipped key carries the packages prefix and keeps lib/', () {
    // Both halves are easy to get wrong: an ordinary package asset implies
    // lib/, a shader does not. Verified against the built bundle, where the
    // file lands at exactly this path.
    expect(
      LiquidGlassShader.assetKey,
      'packages/glassy_bottom_nav/$_keyUnderTest',
    );
  });

  group('when the asset cannot be loaded', () {
    // Which is the case under flutter_test, since the test bundle drops the
    // packages/ prefix that the shipped key carries.
    late List<FlutterErrorDetails> errors;

    setUp(() {
      errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);
    });

    test('it reports rather than throws, and stays failed', () async {
      await LiquidGlassShader.load();

      expect(LiquidGlassShader.failed, isTrue);
      expect(LiquidGlassShader.program, isNull);
      expect(errors, hasLength(1));
      expect(errors.single.library, 'glassy_bottom_nav');
    });

    test('it is not retried', () async {
      await LiquidGlassShader.load();
      await LiquidGlassShader.load();
      await LiquidGlassShader.load();

      // A shader that is not going to appear should cost one attempt, not
      // one per frame of the rest of the session.
      expect(errors, hasLength(1));
    });
  });

  test('concurrent loads share one attempt', () async {
    final errors = <FlutterErrorDetails>[];
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    await Future.wait<void>([
      LiquidGlassShader.load(),
      LiquidGlassShader.load(),
      LiquidGlassShader.load(),
    ]);

    expect(errors, hasLength(1));
  });
}
