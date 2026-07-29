// Renders the README screenshot from the real widget, so it can be refreshed
// whenever the bar changes:
//
//   flutter test tool/generate_screenshot.dart --update-goldens
//
// It lives outside test/ on purpose. `flutter test` only picks up test/, so CI
// never runs this and never fails on a font or platform rendering difference.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

/// The test environment ships a placeholder font that draws every glyph as a
/// box, so the real fonts have to be loaded for labels and icons to appear.
Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!fonts.existsSync()) {
    throw StateError('Set FLUTTER_ROOT so the bundled fonts can be found.');
  }

  Future<void> load(String family, String file) async {
    final bytes = File('${fonts.path}/$file').readAsBytesSync();
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }

  await load('Roboto', 'Roboto-Regular.ttf');
  await load('MaterialIcons', 'MaterialIcons-Regular.otf');
}

const List<GlassyBottomNavItem> _items = [
  GlassyBottomNavItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: 'Home',
    activeColor: Colors.greenAccent,
  ),
  GlassyBottomNavItem(
    icon: Icon(Icons.favorite_border),
    activeIcon: Icon(Icons.favorite),
    label: 'Favorite',
    activeColor: Colors.redAccent,
  ),
  GlassyBottomNavItem(
    icon: Icon(Icons.book_outlined),
    activeIcon: Icon(Icons.book),
    label: 'Books',
    activeColor: Colors.lightBlueAccent,
  ),
  GlassyBottomNavItem(
    icon: Icon(Icons.playlist_add),
    activeIcon: Icon(Icons.playlist_add_check),
    label: 'Playlist',
    activeColor: Colors.pinkAccent,
  ),
];

void main() {
  testWidgets('render the README screenshot', (tester) async {
    await _loadFonts();

    tester.view
      ..physicalSize = const Size(1000, 660)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const _Sheet(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(_Sheet),
      matchesGoldenFile('../screenshots/glassy_bottom_nav.png'),
    );
  });
}

/// Both layouts side by side, each captioned.
class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    // A Material ancestor, or the captions pick up the debug underline.
    return Material(
      color: const Color(0xFF0D0D14),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          children: const [
            Expanded(
              child: _Panel(
                caption: 'GlassyNavbarType.centered',
                navbarType: GlassyNavbarType.centered,
                selectedIndex: 1,
              ),
            ),
            SizedBox(width: 32),
            Expanded(
              child: _Panel(
                caption: 'GlassyNavbarType.bottom',
                navbarType: GlassyNavbarType.bottom,
                selectedIndex: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.caption,
    required this.navbarType,
    required this.selectedIndex,
  });

  final String caption;
  final GlassyNavbarType navbarType;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              body: const _Backdrop(),
              bottomNavigationBar: GlassyBottomNav(
                currentIndex: selectedIndex,
                navbarType: navbarType,
                backgroundColor: Colors.black,
                backgroundBlur: 20,
                borderThickness: 0.5,
                borderColor: const Color(0x26FFFFFF),
                items: _items,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          caption,
          style: const TextStyle(
            color: Color(0xFF8A8AA3),
            fontSize: 15,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}

/// Something worth blurring: colour blobs and a few cards.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241B3D), Color(0xFF4A1C44), Color(0xFF0F2C43)],
        ),
      ),
      child: Stack(
        children: [
          _blob(const Alignment(-0.9, -0.7), const Color(0xFF7C4DFF), 180),
          _blob(const Alignment(1.0, 0.1), const Color(0xFF00BFA5), 160),
          _blob(const Alignment(-0.2, 1.0), const Color(0xFFFF6D00), 200),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final line in const ['Discover', 'Recently played', 'Mixes'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    height: 66,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          line,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Soft-edged so the backdrop reads as a photograph rather than flat discs.
  Widget _blob(Alignment alignment, Color color, double size) => Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0)
              ],
            ),
          ),
        ),
      );
}
