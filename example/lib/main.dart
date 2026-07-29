import 'package:flutter/material.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

import 'demo_ui.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glassy_bottom_nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class _Destination {
  const _Destination({
    required this.title,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.page,
  });

  final String title;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final Widget page;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  /// The example drives the bar from here instead of letting it track the
  /// selection itself, so swiping the pages and tapping the bar stay in sync.
  int _index = 0;

  GlassyNavbarType _navbarType = GlassyNavbarType.centered;

  static const List<_Destination> _destinations = [
    _Destination(
      title: 'Discover',
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_filled,
      color: Color(0xFF3DDC97),
      page: DiscoverPage(),
    ),
    _Destination(
      title: 'Favorites',
      label: 'Favorite',
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      color: Color(0xFFFF4D8D),
      page: FavoritesPage(),
    ),
    _Destination(
      title: 'Library',
      label: 'Books',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      color: Color(0xFF2E86FF),
      page: LibraryPage(),
    ),
    _Destination(
      title: 'Playlist',
      label: 'Playlist',
      icon: Icons.queue_music_outlined,
      activeIcon: Icons.queue_music_rounded,
      color: Color(0xFF9B5CFF),
      page: PlaylistPage(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets the pages paint behind the bar, which is what gives the glass
      // something to blur.
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _index = index),
            children: [
              for (final destination in _destinations) destination.page,
            ],
          ),
          const _TopScrim(),
          _Header(
            title: _destinations[_index].title,
            navbarType: _navbarType,
            onNavbarTypeChanged: (type) => setState(() => _navbarType = type),
          ),
        ],
      ),
      bottomNavigationBar: GlassyBottomNav(
        currentIndex: _index,
        onChange: _goTo,
        navbarType: _navbarType,
        backgroundColor: Colors.black,
        backgroundBlur: 22,
        borderThickness: 0.5,
        borderColor: Colors.white.withValues(alpha: 0.14),
        showUnselectedLabel: false,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          for (final destination in _destinations)
            GlassyBottomNavItem(
              icon: Icon(destination.icon),
              activeIcon: Icon(destination.activeIcon),
              label: destination.label,
              activeColor: destination.color,
            ),
        ],
      ),
    );
  }
}

/// Fades the pages out as they scroll up behind the header.
class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.paddingOf(context).top + 76,
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBackground, Color(0x00000000)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.navbarType,
    required this.onNavbarTypeChanged,
  });

  final String title;
  final GlassyNavbarType navbarType;
  final ValueChanged<GlassyNavbarType> onNavbarTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GLASSY',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _LayoutToggle(value: navbarType, onChanged: onNavbarTypeChanged),
          ],
        ),
      ),
    );
  }
}

/// Switches the bar between its two layouts.
class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({required this.value, required this.onChanged});

  final GlassyNavbarType value;
  final ValueChanged<GlassyNavbarType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in GlassyNavbarType.values)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: type == value
                      ? const Color(0x26FFFFFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type.name,
                  style: TextStyle(
                    color: type == value ? kText : kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
