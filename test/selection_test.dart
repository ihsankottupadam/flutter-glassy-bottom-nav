import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

import 'helpers.dart';

void main() {
  testWidgets('starts on initialIndex', (tester) async {
    await tester.pumpNav(const GlassyBottomNav(items: items, initialIndex: 1));

    expect(find.byIcon(selectedIconOf(1)), findsOneWidget);
    expect(find.byIcon(unselectedIconOf(0)), findsOneWidget);
  });

  testWidgets('tapping an item selects it and reports the index', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpNav(GlassyBottomNav(items: items, onChange: changes.add));

    await tester.tap(find.byIcon(unselectedIconOf(2)));
    await tester.pumpAndSettle();

    expect(changes, [2]);
    expect(find.byIcon(selectedIconOf(2)), findsOneWidget);
    expect(find.byIcon(unselectedIconOf(0)), findsOneWidget);
  });

  testWidgets('tapping the selected item is ignored', (tester) async {
    final changes = <int>[];
    await tester.pumpNav(GlassyBottomNav(items: items, onChange: changes.add));

    await tester.tap(find.byIcon(selectedIconOf(0)));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
  });

  testWidgets('taps land anywhere in the item, not just on the icon', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpNav(GlassyBottomNav(items: items, onChange: changes.add));

    // The empty strip above the icon still belongs to the item.
    final target = tester.getTopLeft(find.byIcon(unselectedIconOf(1)));
    await tester.tapAt(Offset(target.dx, target.dy - 6));
    await tester.pumpAndSettle();

    expect(changes, [1]);
  });

  group('controlled', () {
    testWidgets('reports taps without moving the selection itself', (
      tester,
    ) async {
      final changes = <int>[];
      await tester.pumpNav(
        GlassyBottomNav(items: items, currentIndex: 0, onChange: changes.add),
      );

      await tester.tap(find.byIcon(unselectedIconOf(3)));
      await tester.pumpAndSettle();

      expect(changes, [3]);
      // The parent has not passed a new currentIndex, so nothing moved.
      expect(find.byIcon(selectedIconOf(0)), findsOneWidget);
      expect(find.byIcon(unselectedIconOf(3)), findsOneWidget);
    });

    testWidgets('follows a new currentIndex', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, currentIndex: 0),
      );
      await tester.pumpNav(
        const GlassyBottomNav(items: items, currentIndex: 3),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(selectedIconOf(3)), findsOneWidget);
      expect(find.byIcon(unselectedIconOf(0)), findsOneWidget);
    });

    testWidgets('overrides initialIndex', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, initialIndex: 1, currentIndex: 2),
      );

      expect(find.byIcon(selectedIconOf(2)), findsOneWidget);
    });
  });

  testWidgets('keeps a valid selection when the item list shrinks', (
    tester,
  ) async {
    await tester.pumpNav(const GlassyBottomNav(items: items, initialIndex: 3));
    await tester.pumpNav(GlassyBottomNav(items: items.sublist(0, 2)));
    await tester.pumpAndSettle();

    expect(find.byIcon(selectedIconOf(1)), findsOneWidget);
  });

  group('rejects', () {
    testWidgets('an empty item list', (tester) async {
      await tester.pumpNav(const GlassyBottomNav(items: []));

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('an out of range initialIndex', (tester) async {
      await tester.pumpNav(
        GlassyBottomNav(items: items, initialIndex: items.length),
      );

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('an out of range currentIndex', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, currentIndex: -1),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}
