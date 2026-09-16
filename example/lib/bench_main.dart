// A raster-time benchmark for the two glass styles, and for the bar drawing
// no filter at all.
//
//     flutter run --profile -t lib/bench_main.dart -d <device>
//
// Modes are `none`, `frosted`, `liquid` and `shader`. Every mode draws the
// same animated backdrop and the same bar geometry, so the only thing that
// differs between them is the filter the bar puts over what is behind it.
//
// `shader` is the liquid style with the blur sigma set to zero, which leaves
// the composed filter and the refraction but takes the blur's work out of
// it. It is not a shipping configuration -- it exists to say how much of
// liquid's cost is the rim and how much is the blur it composes with.
//
// **One run measures every mode.** The app cycles modes itself, several
// rounds of them, rather than being rebuilt and reinstalled per mode. Two
// reasons, both learned the hard way on the handset these numbers come from:
// a 69 MB reinstall between every reading is where a flaky USB link drops,
// and cycling in-process interleaves the modes by construction, so a phone
// that warms up over the run spreads that drift across all four modes
// instead of penalising whichever ran last.
//
// The backdrop moves every frame on purpose: a still one lets the raster
// cache keep the filtered layer and the numbers then measure nothing.
//
// It prints one line per batch, which is what the run script reads back out
// of logcat:
//
//     BENCH round=0 mode=liquid batch=2 n=120 mean=1.83 p50=1.79 p90=2.12 over16=0
//
// Batches rather than one long average because frames inside a batch are
// correlated -- the interesting variance is between batches and between
// rounds, and a single mean over 600 frames hides both.
//
// Throwaway, like `probe_main.dart`: it is committed so the raster-time
// figures quoted in the 1.1.0 release notes can be reproduced, not because
// the package needs it.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

/// The modes, in the order each round walks them.
const List<String> _modes = <String>['none', 'frosted', 'liquid', 'shader'];

/// Frames dropped after every switch, before anything is recorded.
///
/// The frames just after a mode change pay for shader compilation, texture
/// upload and the raster cache warming, none of which repeat and all of
/// which would otherwise land on whichever mode ran first.
const int _warmupFrames = 180;

/// Frames per reported batch, batches per mode, and rounds of all modes.
const int _batchSize = 120;
const int _batches = 4;
const int _rounds = 3;

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
  int _segment = 0;
  bool _finished = false;

  /// The mode being measured right now, and which pass over the list it is.
  String get _mode => _modes[_segment % _modes.length];
  int get _round => _segment ~/ _modes.length;

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
      if (_finished) return;
      _seen++;
      if (_seen <= _warmupFrames) continue;

      _batch.add(timing.rasterDuration.inMicroseconds / 1000.0);
      if (_batch.length < _batchSize) continue;

      final List<double> sorted = List<double>.of(_batch)..sort();
      final double mean = _batch.reduce((a, b) => a + b) / _batch.length;
      final int over = _batch.where((double d) => d > 16.67).length;
      // ignore: avoid_print
      print(
        'BENCH round=$_round mode=$_mode batch=$_reported n=${_batch.length} '
        'mean=${mean.toStringAsFixed(3)} '
        'p50=${sorted[sorted.length ~/ 2].toStringAsFixed(3)} '
        'p90=${sorted[(sorted.length * 9) ~/ 10].toStringAsFixed(3)} '
        'over16=$over',
      );
      _batch.clear();
      _reported++;
      if (_reported == _batches) _advance();
    }
  }

  /// Moves to the next mode, or stops once every round has been walked.
  ///
  /// The rebuild has to happen outside the timings callback -- it runs
  /// during frame reporting, where calling setState would be building a
  /// widget while a frame is being handed back.
  void _advance() {
    _reported = 0;
    _seen = 0;
    if (_segment + 1 >= _modes.length * _rounds) {
      _finished = true;
      // ignore: avoid_print
      print('BENCH all done');
      return;
    }
    scheduleMicrotask(() {
      if (mounted) setState(() => _segment++);
    });
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
      bottomNavigationBar: KeyedSubtree(
        key: ValueKey<int>(_segment),
        child: _mode == 'none' ? const _PlainBar() : _glassBar(),
      ),
    );
  }

  Widget _glassBar() => GlassyBottomNav(
    currentIndex: 0,
    onChange: (_) {},
    glassStyle: _mode == 'frosted' ? GlassStyle.frosted : GlassStyle.liquid,
    backgroundColor: Colors.black,
    backgroundBlur: _mode == 'shader' ? 0 : 10,
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
/// frame and cannot be cached, while costing little enough that the floor
/// mode sits well inside the frame budget.
///
/// The first cut drew ~40 rounded rects a frame and put the no-filter floor
/// on the vsync boundary, where raster time stops measuring work and starts
/// measuring back-pressure. One shifting gradient and six blocks leave
/// headroom for the filter's own cost to show.
class _DriftingArtwork extends CustomPainter {
  const _DriftingArtwork(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = t * 2 * math.pi;
    final Rect full = Offset.zero & size;

    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(math.cos(phase), math.sin(phase)),
          end: Alignment(-math.cos(phase), -math.sin(phase)),
          colors: const <Color>[
            Color(0xff7c5cff), Color(0xff2ec5b6), Color(0xffff6b6b),
            Color(0xff4d7cff),
          ],
        ).createShader(full),
    );

    // A few hard edges so the rim has something with contrast to bend, and
    // so the backdrop is not a smooth field the filter can cheat on.
    final double band = size.height / 6;
    for (int i = 0; i < 6; i++) {
      if (i.isEven) continue;
      final double y = ((i * band) + t * size.height) % (size.height + band);
      canvas.drawRect(
        Rect.fromLTWH(0, y - band, size.width, band * 0.45),
        Paint()..color = const Color(0x33000000),
      );
    }
  }

  @override
  bool shouldRepaint(_DriftingArtwork oldDelegate) => oldDelegate.t != t;
}
