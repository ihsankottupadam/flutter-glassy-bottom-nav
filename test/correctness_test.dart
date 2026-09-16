import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

import 'helpers.dart';

/// A home-indicator sized inset, the case all three of these got wrong.
const EdgeInsets _homeIndicator = EdgeInsets.only(bottom: 34);

/// The bar's own painted box, inside whatever margin is around it.
Rect _panel(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(GlassyBottomNav),
            matching: find.byType(ClipRRect),
          )
          .first,
    );

void main() {
  group('bottom inset', () {
    testWidgets('keeps the docked bar clear of the home indicator', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(
            items: items, navbarType: GlassyNavbarType.bottom),
        padding: _homeIndicator,
      );

      final double screenBottom = tester.getSize(find.byType(Scaffold)).height;
      expect(
        _panel(tester).bottom,
        moreOrLessEquals(screenBottom - 34),
        reason: 'the docked bar should stop where the safe area starts',
      );
    });

    testWidgets('leaves the docked bar flush when there is no inset', (
      tester,
    ) async {
      await tester.pumpNav(
        const GlassyBottomNav(
            items: items, navbarType: GlassyNavbarType.bottom),
      );

      final double screenBottom = tester.getSize(find.byType(Scaffold)).height;
      expect(_panel(tester).bottom, moreOrLessEquals(screenBottom));
    });

    testWidgets('grows the floating pill only past what it already left', (
      tester,
    ) async {
      // The pill's own 20px bottom margin is more than this inset asks for,
      // so it should not move at all.
      await tester.pumpNav(
        const GlassyBottomNav(items: items),
        padding: const EdgeInsets.only(bottom: 12),
      );
      final double screenBottom = tester.getSize(find.byType(Scaffold)).height;
      expect(_panel(tester).bottom, moreOrLessEquals(screenBottom - 20));

      // A larger inset does move it.
      await tester.pumpNav(
        const GlassyBottomNav(items: items),
        padding: _homeIndicator,
      );
      expect(_panel(tester).bottom, moreOrLessEquals(screenBottom - 34));
    });

    testWidgets('an explicit margin is left exactly as given', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(
          items: items,
          navbarType: GlassyNavbarType.bottom,
          margin: EdgeInsets.only(bottom: 4),
        ),
        padding: _homeIndicator,
      );

      final double screenBottom = tester.getSize(find.byType(Scaffold)).height;
      expect(
        _panel(tester).bottom,
        moreOrLessEquals(screenBottom - 4),
        reason: 'a caller asking for 4 should get 4, not 4 grown to 34',
      );
    });
  });

  group('right to left', () {
    testWidgets('puts the indicator over the selected item', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items, initialIndex: 1),
        textDirection: TextDirection.rtl,
      );
      await tester.pumpAndSettle();

      final Rect indicator = tester.getRect(
        find.byType(AnimatedPositionedDirectional),
      );
      final Rect icon = tester.getRect(find.byIcon(selectedIconOf(1)));

      expect(
        indicator.left,
        lessThanOrEqualTo(icon.left),
        reason: 'the indicator should cover the selected icon, not mirror '
            'away from it',
      );
      expect(indicator.right, greaterThanOrEqualTo(icon.right));
    });

    testWidgets('mirrors: item 0 sits on the right', (tester) async {
      await tester.pumpNav(
        const GlassyBottomNav(items: items),
        textDirection: TextDirection.rtl,
      );
      await tester.pumpAndSettle();

      final double first = tester.getCenter(find.byIcon(selectedIconOf(0))).dx;
      final double last =
          tester.getCenter(find.byIcon(unselectedIconOf(items.length - 1))).dx;
      expect(
        first,
        greaterThan(last),
        reason: 'under rtl the first destination is the rightmost',
      );
    });

    testWidgets('still tracks taps under rtl', (tester) async {
      int? tapped;
      await tester.pumpNav(
        GlassyBottomNav(items: items, onChange: (i) => tapped = i),
        textDirection: TextDirection.rtl,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(unselectedIconOf(2)));
      await tester.pumpAndSettle();

      expect(tapped, 2);
      final Rect indicator = tester.getRect(
        find.byType(AnimatedPositionedDirectional),
      );
      final Rect icon = tester.getRect(find.byIcon(selectedIconOf(2)));
      expect(indicator.left, lessThanOrEqualTo(icon.left));
      expect(indicator.right, greaterThanOrEqualTo(icon.right));
    });
  });

  group('semantics', () {
    testWidgets('announces each item as a button in an exclusive group', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpNav(const GlassyBottomNav(items: items));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Favorite')),
        matchesSemantics(
          label: 'Favorite',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('marks the selected item selected', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpNav(
        const GlassyBottomNav(items: items, initialIndex: 2),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Books')),
        matchesSemantics(
          label: 'Books',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    // A guard rather than a proof: this passed before the fix too. It is
    // here so that a later change adding a second labelled node -- an
    // un-excluded Tooltip, a label on the icon -- fails loudly.
    testWidgets('each label is exactly one node', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpNav(const GlassyBottomNav(items: items));

      // The label is drawn as Text, carried by the Tooltip and set on the
      // Semantics node. A reader should still meet it exactly once.
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      handle.dispose();
    });

    // Also a guard, and the one that matters most: excludeSemantics drops
    // the GestureDetector's own tap action, so without the onTap moved up
    // onto the Semantics node this bar would be unusable with a reader.
    testWidgets('a screen reader can activate an item', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int? tapped;
      await tester.pumpNav(
        GlassyBottomNav(items: items, onChange: (i) => tapped = i),
      );

      tester.semantics.tap(find.semantics.byLabel('Playlist'));
      await tester.pumpAndSettle();

      expect(tapped, items.length - 1);
      handle.dispose();
    });
  });
}
