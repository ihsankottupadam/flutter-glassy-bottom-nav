import 'package:flutter/material.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glassy_bottom_nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const HomePage(),
    );
  }
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
      icon: Icons.home_outlined,
      activeIcon: Icons.home_filled,
      label: 'Home',
      color: Colors.green,
    ),
    _Destination(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Favorite',
      color: Colors.red,
    ),
    _Destination(
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: 'Books',
      color: Colors.blue,
    ),
    _Destination(
      icon: Icons.playlist_add,
      activeIcon: Icons.playlist_add_check,
      label: 'Playlist',
      color: Colors.pink,
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets the body paint behind the bar, which is what gives the glass
      // something to blur.
      extendBody: true,
      body: Stack(
        children: [
          const _Backdrop(),
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _index = index),
            children: [
              for (final destination in _destinations)
                _Page(destination: destination),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<GlassyNavbarType>(
                  segments: const [
                    ButtonSegment(
                      value: GlassyNavbarType.centered,
                      label: Text('centered'),
                    ),
                    ButtonSegment(
                      value: GlassyNavbarType.bottom,
                      label: Text('bottom'),
                    ),
                  ],
                  selected: {_navbarType},
                  onSelectionChanged: (selection) =>
                      setState(() => _navbarType = selection.first),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlassyBottomNav(
        currentIndex: _index,
        onChange: _goTo,
        navbarType: _navbarType,
        backgroundColor: Colors.black,
        backgroundBlur: 20,
        borderThickness: 0.5,
        borderColor: Colors.white.withValues(alpha: 0.15),
        showUnselectedLabel: false,
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

class _Destination {
  const _Destination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
}

/// The page behind the bar, deliberately busy so the blur has something to
/// chew on.
class _Page extends StatelessWidget {
  const _Page({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 96, 16, 120),
      itemCount: 12,
      itemBuilder: (context, index) => Card(
        color: destination.color.withValues(alpha: 0.25),
        child: ListTile(
          leading: Icon(destination.activeIcon),
          title: Text('${destination.label} ${index + 1}'),
          subtitle: const Text('Scroll me under the glass'),
        ),
      ),
    );
  }
}

/// Colour blobs on a dark gradient, so the bar has something to blur without
/// the example needing an image asset.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1B2F), Color(0xFF3A1C4A), Color(0xFF102A43)],
        ),
      ),
      child: Stack(
        children: [
          _blob(const Alignment(-0.8, -0.6), Colors.purple),
          _blob(const Alignment(0.9, -0.2), Colors.teal),
          _blob(const Alignment(-0.3, 0.9), Colors.orange),
        ],
      ),
    );
  }

  Widget _blob(Alignment alignment, Color color) => Align(
    alignment: alignment,
    child: Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
    ),
  );
}
