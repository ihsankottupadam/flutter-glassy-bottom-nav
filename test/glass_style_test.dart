import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

import 'helpers.dart';

/// The runtime types of every widget pumped, in tree order.
///
/// The whole tree rather than the bar's subtree: every comparison below
/// pumps the same wrapper either side, so anything that differs came from
/// the bar. Structural rather than visual — what it pins is that a bar
/// built one way produces the same tree as a bar built another, which is
/// the claim that the style parameter is additive.
List<Type> _pumpedTree(WidgetTester tester) => tester.allWidgets
    .map((widget) => widget.runtimeType)
    .toList(growable: false);

void main() {
  group('resolveFor', () {
    // The real logic, tested where both branches are reachable.
    // GlassStyle.resolved reads ui.ImageFilter.isShaderFilterSupported,
    // which is always false under flutter_test, so the liquid branch can
    // only be reached by supplying the capability.
    test('liquid survives where the backend can run shaders', () {
      expect(
        GlassStyle.liquid.resolveFor(shadersSupported: true),
        GlassStyle.liquid,
      );
    });

    test('liquid falls back to frosted where it cannot', () {
      expect(
        GlassStyle.liquid.resolveFor(shadersSupported: false),
        GlassStyle.frosted,
      );
    });

    test('frosted is unaffected either way', () {
      expect(
        GlassStyle.frosted.resolveFor(shadersSupported: true),
        GlassStyle.frosted,
      );
      expect(
        GlassStyle.frosted.resolveFor(shadersSupported: false),
        GlassStyle.frosted,
      );
    });
  });

  group('resolved', () {
    test('is frosted under flutter_test, which runs on Skia', () {
      // Not a tautology worth deleting: it is the assertion that the
      // fallback is what a backend without ImageFilter.shader really gets,
      // and it will start failing if flutter_test ever gains Impeller.
      expect(GlassStyle.liquid.resolved, GlassStyle.frosted);
      expect(GlassStyle.frosted.resolved, GlassStyle.frosted);
    });
  });

  group('the bar', () {
    testWidgets('defaults to frosted', (tester) async {
      await tester.pumpNav(const GlassyBottomNav(items: items));

      expect(
        tester.widget<GlassyBottomNav>(find.byType(GlassyBottomNav)).glassStyle,
        GlassStyle.frosted,
      );
    });

    testWidgets('keeps the style it was given on the widget', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, glassStyle: GlassStyle.liquid),
      );

      // The parameter is reported as asked for; only the resolved value
      // falls back, so a caller can still see what they requested.
      expect(
        tester.widget<GlassyBottomNav>(find.byType(GlassyBottomNav)).glassStyle,
        GlassStyle.liquid,
      );
    });

    testWidgets('reports the fallback in its diagnostics', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, glassStyle: GlassStyle.liquid),
      );

      final properties = tester
          .state(find.byType(GlassyBottomNav))
          .toDiagnosticsNode()
          .getProperties();
      final resolved = properties.firstWhere(
        (property) => property.name == 'resolvedStyle',
      );

      // A silent downgrade is invisible in the inspector unless it is said
      // out loud, which is what this property is for.
      expect(resolved.value, GlassStyle.frosted);
    });

    testWidgets('asking for liquid draws the frosted tree here', (
      tester,
    ) async {
      await tester.pumpNav(const GlassyBottomNav(items: items));
      final frosted = _pumpedTree(tester);

      await tester.pumpNav(
        const GlassyBottomNav(items: items, glassStyle: GlassStyle.liquid),
      );

      expect(_pumpedTree(tester), frosted);
    });

    testWidgets('the default builds the same tree as an explicit frosted', (
      tester,
    ) async {
      await tester.pumpNav(const GlassyBottomNav(items: items));
      final byDefault = _pumpedTree(tester);

      await tester.pumpNav(
        const GlassyBottomNav(items: items, glassStyle: GlassStyle.frosted),
      );

      expect(_pumpedTree(tester), byDefault);
    });

    testWidgets('draws exactly one BackdropFilter while frosted', (
      tester,
    ) async {
      // The guard on Phase 3: the liquid style adds a second filter above
      // the blur, and frosted must never grow one.
      await tester.pumpNav(const GlassyBottomNav(items: items));

      expect(
        find.descendant(
          of: find.byType(GlassyBottomNav),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });
  });
}
