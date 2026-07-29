import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

import 'helpers.dart';

/// The outermost widget of the given type inside the bar.
T _firstInNav<T extends Widget>(WidgetTester tester) => tester.widget<T>(
      find
          .descendant(
              of: find.byType(GlassyBottomNav), matching: find.byType(T))
          .first,
    );

/// The decoration of the glass panel itself.
///
/// Scoped to the [BackdropFilter], since the indicator's [AnimatedContainer]
/// also builds a [Container] and sits earlier in the tree.
BoxDecoration _glassDecoration(WidgetTester tester) => tester
    .widget<Container>(
      find
          .descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(Container),
          )
          .first,
    )
    .decoration! as BoxDecoration;

void main() {
  group('background indicator', () {
    testWidgets('is shown by default and tracks the selected item', (
      tester,
    ) async {
      await tester.pumpNav(const GlassyBottomNav(items: items));
      await tester.pumpAndSettle();

      final itemWidth = tester
              .getSize(
                find
                    .descendant(
                      of: find.byType(GlassyBottomNav),
                      matching: find.byType(ClipRRect),
                    )
                    .first,
              )
              .width /
          items.length;

      expect(
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left,
        0,
      );

      await tester.tap(find.byIcon(unselectedIconOf(2)));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left,
        moreOrLessEquals(itemWidth * 2),
      );
    });

    testWidgets('is omitted when showBackgroundIndicator is false', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, showBackgroundIndicator: false),
      );

      expect(find.byType(AnimatedPositioned), findsNothing);
    });
  });

  group('navbar type', () {
    testWidgets('centered floats as a fully rounded pill', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(
          items: items,
          navbarType: GlassyNavbarType.centered,
        ),
      );

      expect(
        _firstInNav<ClipRRect>(tester).borderRadius,
        BorderRadius.circular(50),
      );
      expect(
        _firstInNav<Padding>(tester).padding,
        const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      );
    });

    testWidgets('bottom is flush with the edge and rounded on top', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(
          items: items,
          navbarType: GlassyNavbarType.bottom,
        ),
      );

      expect(
        _firstInNav<ClipRRect>(tester).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(25)),
      );
      expect(_firstInNav<Padding>(tester).padding, EdgeInsets.zero);
    });

    testWidgets('borderRadius overrides the default of either type', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(
          items: items,
          navbarType: GlassyNavbarType.bottom,
          borderRadius: 8,
        ),
      );

      expect(
        _firstInNav<ClipRRect>(tester).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(8)),
      );
    });

    testWidgets('margin overrides the default of either type', (tester) async {
      const margin = EdgeInsets.all(4);
      await tester.pumpNav(const GlassyBottomNav(items: items, margin: margin));

      expect(_firstInNav<Padding>(tester).padding, margin);
    });
  });

  group('glass', () {
    testWidgets('blurs the backdrop by backgroundBlur', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, backgroundBlur: 42),
      );

      final filter = _firstInNav<BackdropFilter>(tester).filter.toString();
      expect(filter, contains('42'));
    });

    testWidgets('tints the glass with a translucent backgroundColor', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, backgroundColor: Colors.black),
      );

      final color = _glassDecoration(tester).color!;
      expect(color.a, moreOrLessEquals(0.1, epsilon: 0.01));
    });

    testWidgets('draws no border unless borderThickness is set', (
      tester,
    ) async {
      await tester.pumpNav(const GlassyBottomNav(items: items));

      expect(_glassDecoration(tester).border, isNull);
    });

    testWidgets('draws the border with the given thickness and colour', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(
          items: items,
          borderThickness: 2,
          borderColor: Colors.pink,
        ),
      );

      expect(
        _glassDecoration(tester).border,
        Border.all(width: 2, color: Colors.pink),
      );
    });
  });

  group('marker', () {
    Iterable<BoxConstraints?> markerConstraints(WidgetTester tester) => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((container) => container.constraints);

    testWidgets('is 20x3 by default and collapses when unselected', (
      tester,
    ) async {
      await tester.pumpNav(const GlassyBottomNav(items: items));
      await tester.pumpAndSettle();

      expect(
        markerConstraints(tester),
        containsAll([
          BoxConstraints.tightFor(width: 20, height: 3),
          BoxConstraints.tightFor(width: 0, height: 3),
        ]),
      );
    });

    testWidgets('honours markerSize', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, markerSize: Size(30, 6)),
      );
      await tester.pumpAndSettle();

      expect(
        markerConstraints(tester),
        contains(BoxConstraints.tightFor(width: 30, height: 6)),
      );
    });
  });

  testWidgets('animates over the given duration', (tester) async {
    await tester.pumpNav(
      GlassyBottomNav(
        items: items,
        duration: const Duration(milliseconds: 400),
      ),
    );

    expect(
      tester
          .widget<AnimatedPositioned>(find.byType(AnimatedPositioned))
          .duration,
      const Duration(milliseconds: 400),
    );
  });
}
