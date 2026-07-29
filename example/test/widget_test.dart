import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

void main() {
  testWidgets('tapping a destination moves the page and retitles the header', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Midnight Drive'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('The Glass Atlas'), findsOneWidget);
  });

  testWidgets('the layout toggle switches the navbar type', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    GlassyNavbarType navbarType() =>
        tester.widget<GlassyBottomNav>(find.byType(GlassyBottomNav)).navbarType;

    expect(navbarType(), GlassyNavbarType.centered);

    await tester.tap(find.text('bottom'));
    await tester.pumpAndSettle();

    expect(navbarType(), GlassyNavbarType.bottom);
  });

  testWidgets('the option button docks a button over the bar', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.byIcon(Icons.add_rounded), findsNothing);

    await tester.tap(find.byTooltip('Center-docked button'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Docked over the centre of the bar.
    final button = tester.getCenter(find.byIcon(Icons.add_rounded));
    final bar = tester.getCenter(find.byType(GlassyBottomNav));
    expect(button.dx, moreOrLessEquals(bar.dx, epsilon: 0.5));
    expect(button.dy, lessThan(bar.dy));
  });
}
