import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

import 'helpers.dart';

TextStyle _styleOf(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  testWidgets('shows every label by default', (tester) async {
    await tester.pumpNav(const GlassyBottomNav(items: items));

    for (final item in items) {
      expect(find.text(item.label), findsOneWidget);
    }
  });

  testWidgets('showUnselectedLabel hides the labels of the other items', (
    tester,
  ) async {
    await tester.pumpNav(
      const GlassyBottomNav(items: items, showUnselectedLabel: false),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Favorite'), findsNothing);
    expect(find.text('Books'), findsNothing);
  });

  testWidgets('showSelectedLabel hides the label of the selected item', (
    tester,
  ) async {
    await tester.pumpNav(
      const GlassyBottomNav(items: items, showSelectedLabel: false),
    );

    expect(find.text('Home'), findsNothing);
    expect(find.text('Favorite'), findsOneWidget);
  });

  testWidgets('applies labelStyle to every label', (tester) async {
    await tester.pumpNav(
      const GlassyBottomNav(
        items: items,
        labelStyle: TextStyle(fontSize: 20, color: Colors.amber),
      ),
    );

    for (final item in items) {
      final style = _styleOf(tester, item.label);
      expect(style.fontSize, 20);
      expect(style.color, Colors.amber);
    }
  });

  testWidgets('selectedLabelStyle only overrides the selected label', (
    tester,
  ) async {
    await tester.pumpNav(
      const GlassyBottomNav(
        items: items,
        labelStyle: TextStyle(fontSize: 20, color: Colors.amber),
        selectedLabelStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final selected = _styleOf(tester, 'Home');
    expect(selected.fontSize, 24);
    expect(selected.fontWeight, FontWeight.bold);
    // Inherited from labelStyle, which selectedLabelStyle did not override.
    expect(selected.color, Colors.amber);

    final unselected = _styleOf(tester, 'Favorite');
    expect(unselected.fontSize, 20);
    expect(unselected.color, Colors.amber);
    expect(unselected.fontWeight, isNot(FontWeight.bold));
  });

  testWidgets('falls back to the default label style', (tester) async {
    await tester.pumpNav(const GlassyBottomNav(items: items));

    final style = _styleOf(tester, 'Home');
    expect(style.color, Colors.white);
    expect(style.fontSize, 12);
  });

  testWidgets('labels every item with a tooltip', (tester) async {
    await tester.pumpNav(const GlassyBottomNav(items: items));

    for (final item in items) {
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Tooltip && widget.message == item.label,
        ),
        findsOneWidget,
      );
    }
  });
}
