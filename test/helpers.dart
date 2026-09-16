import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

/// Four destinations, each with a distinct icon pair so tests can tell the
/// selected item from the rest.
const List<GlassyBottomNavItem> items = [
  GlassyBottomNavItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: 'Home',
    activeColor: Colors.green,
  ),
  GlassyBottomNavItem(
    icon: Icon(Icons.favorite_border),
    activeIcon: Icon(Icons.favorite),
    label: 'Favorite',
    activeColor: Colors.red,
  ),
  GlassyBottomNavItem(
    icon: Icon(Icons.book_outlined),
    activeIcon: Icon(Icons.book),
    label: 'Books',
    activeColor: Colors.blue,
  ),
  GlassyBottomNavItem(
    icon: Icon(Icons.playlist_add),
    activeIcon: Icon(Icons.playlist_add_check),
    label: 'Playlist',
  ),
];

/// The icon [items] shows at [index] while it is selected.
IconData selectedIconOf(int index) =>
    ((items[index].activeIcon ?? items[index].icon) as Icon).icon!;

/// The icon [items] shows at [index] while it is not selected.
IconData unselectedIconOf(int index) => (items[index].icon as Icon).icon!;

extension PumpNav on WidgetTester {
  /// Pumps [nav] as the bottom bar of a plain dark-themed app.
  ///
  /// [padding] stands in for a display's safe-area insets and
  /// [textDirection] for a right-to-left locale; both default to the plain
  /// case so existing tests read the same as before.
  Future<void> pumpNav(
    GlassyBottomNav nav, {
    EdgeInsets padding = EdgeInsets.zero,
    TextDirection textDirection = TextDirection.ltr,
  }) =>
      pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: padding),
            child: Directionality(textDirection: textDirection, child: child!),
          ),
          home: Scaffold(extendBody: true, bottomNavigationBar: nav),
        ),
      );
}
