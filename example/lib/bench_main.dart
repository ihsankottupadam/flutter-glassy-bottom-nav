// A raster-time benchmark for the two glass styles, and for the bar drawing
// no filter at all.
//
//     flutter run --profile -t lib/bench_main.dart -d <device> \
//       --dart-define=BENCH_MODE=liquid
//
// Modes are `none`, `frosted` and `liquid`. Every mode draws the same
// animated backdrop and the same bar geometry, so the only thing that
// differs between them is the filter the bar puts over what is behind it.
//
// The backdrop moves every frame on purpose: a still one lets the raster
// cache keep the filtered layer and the numbers then measure nothing.
//
// It prints one line per batch, which is what the run script reads back out
// of logcat:
//
//     BENCH mode=liquid batch=2 n=120 mean=1.83 p50=1.79 p90=2.12
//
// Batches rather than one long average because frames inside a batch are
// correlated -- the interesting variance is between batches and between
// launches, and a single mean over 600 frames hides both.
//
// Throwaway, like `probe_main.dart`: it is committed so the numbers in
// `doc/research/plan-liquid-glass.md` can be reproduced, not because the
// package needs it.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

const String _mode = String.fromEnvironment('BENCH_MODE', defaultValue: 'liquid');

/// Frames dropped before anything is recorded.
///
/// The first frames of a run pay for shader compilation, texture upload and
/// the raster cache warming, none of which repeat and all of which would
/// land on whichever mode ran first.
const int _warmupFrames = 180;

/// Frames per reported batch, and how many batches before the run stops.
const int _batchSize = 120;
const int _batches = 6;

void main() => runApp(const _BenchApp());

class _BenchApp extends StatelessWidget {
  const _BenchApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _BenchPage(),
    );
  }
}

class _BenchPage extends StatefulWidget {
  const _BenchPage();

  @override
  State<_BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<_BenchPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  final List<double> _batch = <double>[];
  int _seen = 0;
  int _reported = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrames);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrames);
    _drift.dispose();
    super.dispose();
  }

  void _onFrames(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      _seen++;
      if (_seen <= _warmupFrames) continue;
      if (_reported >= _batches) continue;

      _batch.add(timing.rasterDuration.inMicroseconds / 1000.0);
      if (_batch.length < _batchSize) continue;

      final List<double> sorted = List<double>.of(_batch)..sort();
      final double mean = _batch.reduce((a, b) => a + b) / _batch.length;
      // ignore: avoid_print
      print(
        'BENCH mode=$_mode batch=$_reported n=${_batch.length} '
        'mean=${mean.toStringAsFixed(3)} '
        'p50=${sorted[sorted.length ~/ 2].toStringAsFixed(3)} '
        'p90=${sorted[(sorted.length * 9) ~/ 10].toStringAsFixed(3)}',
      );
      _batch.clear();
      _reported++;
      if (_reported == _batches) {
        // ignore: avoid_print
        print('BENCH mode=$_mode done');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) => CustomPaint(
          painter: _DriftingArtwork(_drift.value),
          size: Size.infinite,
        ),
      ),
      bottomNavigationBar: _mode == 'none' ? const _PlainBar() : _glassBar(),
    );
  }

  Widget _glassBar() => GlassyBottomNav(
    currentIndex: 0,
    onChange: (_) {},
    glassStyle: _mode == 'liquid' ? GlassStyle.liquid : GlassStyle.frosted,
    backgroundColor: Colors.black,
    backgroundBlur: 10,
    borderThickness: 0.5,
    borderColor: Colors.white.withValues(alpha: 0.14),
    showUnselectedLabel: false,
    items: _items,
  );
}

const List<GlassyBottomNavItem> _items = <GlassyBottomNavItem>[
  GlassyBottomNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
  GlassyBottomNavItem(icon: Icon(Icons.favorite_border), label: 'Favorite'),
  GlassyBottomNavItem(icon: Icon(Icons.menu_book_outlined), label: 'Books'),
  GlassyBottomNavItem(icon: Icon(Icons.queue_music_outlined), label: 'Playlist'),
];

/// The floor: the bar's geometry and contents with no filter behind them.
///
/// Matches [GlassyNavbarType.centered]'s margin and radius so the layout,
/// the clip and the painted area are the same as the two glass modes and
/// the only difference left is the filter.
class _PlainBar extends StatelessWidget {
  const _PlainBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: GlassyNavbarType.centered.defaultMargin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              width: 0.5,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: <Widget>[
              for (final (int index, GlassyBottomNavItem item)
                  in _items.indexed)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // The same spacing the real item view uses, so this
                      // bar is the same height as the two glass ones. A
                      // shorter bar would clip and filter a smaller area
                      // and quietly flatter the floor.
                      SizedBox(height: index == 0 ? 3 : 0),
                      const SizedBox(height: 10),
                      item.icon,
                      const SizedBox(height: 5),
                      if (index == 0)
                        const Text(
                          'Home',
                          maxLines: 1,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large moving colour, so the backdrop under the bar is different every
/// frame and has enough contrast for the rim to have something to bend.
class _DriftingArtwork extends CustomPainter {
  const _DriftingArtwork(this.t);

  final double t;

  static const List<Color> _colors = <Color>[
    Color(0xff7c5cff), Color(0xff2ec5b6), Color(0xffff6b6b),
    Color(0xff4d7cff), Color(0xffffa94d), Color(0xffb84dff),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff0b0b12));

    final double phase = t * 2 * math.pi;
    const double tile = 150;
    final double shift = (t * tile * 2) % (tile * 2);

    // A drifting checker of colour blocks: high contrast, cheap to paint,
    // and it moves under the bar rather than only changing hue, so the
    // filter sees new input rather than a recoloured copy of the old one.
    for (int row = -2; row * tile < size.height + tile * 2; row++) {
      for (int col = -2; col * tile < size.width + tile * 2; col++) {
        final Color color = _colors[(row + col * 3).abs() % _colors.length];
        final double wobble = math.sin(phase + row * 0.6 + col * 0.4) * 18;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * tile + shift - tile,
              row * tile + wobble,
              tile - 10,
              tile - 10,
            ),
            const Radius.circular(18),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DriftingArtwork oldDelegate) => oldDelegate.t != t;
}
