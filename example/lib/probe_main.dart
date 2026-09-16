// Probe entrypoint, not part of the shipped example.
//
//   flutter run -t lib/probe_main.dart
//
// Answers two questions that decide the shape of a liquid-glass style:
//
//  1. Can the refraction be anchored inside a plain BackdropFilter, with no
//     OffsetLayer.toImageSync capture of the source? The `liquidDebug` mode
//     paints the SDF band; if it traces the bar exactly, the answer is yes.
//  2. What does it cost against the blur that ships today? The readout is the
//     rolling raster time, which is where a per-frame pipeline flush would
//     show up.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const ProbeApp());

/// How the bar's backdrop is filtered.
enum ProbeMode {
  /// No filter at all -- the floor for the raster time.
  none,

  /// ImageFilter.blur, exactly what GlassyBottomNav does today.
  blur,

  /// The refraction shader, anchored by uniforms.
  liquid,

  /// The refraction shader painting its SDF band instead of refracting.
  liquidDebug,

  /// Today's clipped blur with the refraction stacked over it.
  ///
  /// The candidate architecture. The blur is a bar-sized BackdropFilter
  /// exactly as GlassyBottomNav draws it now; the shader is a second,
  /// full-screen BackdropFilter above it, so its input already contains the
  /// blurred bar. Outside the SDF it passes through untouched, which is why a
  /// full-screen pass does not blur the rest of the screen.
  stacked;

  String get label => switch (this) {
    ProbeMode.none => 'none',
    ProbeMode.blur => 'blur',
    ProbeMode.liquid => 'liquid',
    ProbeMode.liquidDebug => 'debug',
    ProbeMode.stacked => 'stacked',
  };
}

/// The bar's geometry, fixed rather than measured so the coordinate-space
/// question is not confounded by a measurement bug.
const double kBarHeight = 64;
const double kBarSideMargin = 16;
const double kBarBottomMargin = 20;
const double kBarRadius = 32;

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProbePage(),
    );
  }
}

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> with TickerProviderStateMixin {
  ui.FragmentProgram? _program;
  Object? _programError;

  ProbeMode _mode = ProbeMode.stacked;
  double _bandWidth = 18;
  double _amount = 22;
  double _blurSigma = 22;

  /// Drives the moving content behind the glass, so the refraction has
  /// something to bend and the raster time is measured under motion.
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  final List<double> _rasterSamples = <double>[];
  double _rasterMs = 0;
  double _uiMs = 0;

  @override
  void initState() {
    super.initState();
    _loadProgram();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  Future<void> _loadProgram() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass_probe.frag',
      );
      if (mounted) setState(() => _program = program);
    } catch (error) {
      if (mounted) setState(() => _programError = error);
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _rasterSamples.add(
        timing.rasterDuration.inMicroseconds / 1000,
      );
      _uiMs = timing.buildDuration.inMicroseconds / 1000;
    }
    if (_rasterSamples.length > 60) {
      _rasterSamples.removeRange(0, _rasterSamples.length - 60);
    }
    final mean =
        _rasterSamples.reduce((a, b) => a + b) / _rasterSamples.length;
    if (mounted) setState(() => _rasterMs = mean);
  }

  void _resetSamples() => _rasterSamples.clear();

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _motion.dispose();
    super.dispose();
  }

  /// The bar's rect in logical pixels, in global coordinates.
  Rect _barRect(Size screen, EdgeInsets padding) {
    final bottom = screen.height - padding.bottom - kBarBottomMargin;
    return Rect.fromLTRB(
      kBarSideMargin,
      bottom - kBarHeight,
      screen.width - kBarSideMargin,
      bottom,
    );
  }

  ui.ImageFilter? _buildFilter(Rect barRect, double dpr) {
    switch (_mode) {
      case ProbeMode.none:
        return null;
      case ProbeMode.blur:
        return ui.ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma);
      case ProbeMode.liquid:
      case ProbeMode.liquidDebug:
      case ProbeMode.stacked:
        final program = _program;
        if (program == null) return null;
        if (!ui.ImageFilter.isShaderFilterSupported) return null;
        final shader = program.fragmentShader();
        final device = Rect.fromLTRB(
          barRect.left * dpr,
          barRect.top * dpr,
          barRect.right * dpr,
          barRect.bottom * dpr,
        );
        shader
          // 0..1 are uTextureSize, which the engine overwrites.
          ..setFloat(0, 0)
          ..setFloat(1, 0)
          ..setFloat(2, device.left)
          ..setFloat(3, device.top)
          ..setFloat(4, device.right)
          ..setFloat(5, device.bottom)
          ..setFloat(6, kBarRadius * dpr)
          ..setFloat(7, _bandWidth * dpr)
          ..setFloat(8, _amount * dpr)
          ..setFloat(9, _mode == ProbeMode.liquidDebug ? 1.0 : 0.0);
        return ui.ImageFilter.shader(shader);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final barRect = _barRect(mq.size, mq.padding);
    final filter = _buildFilter(barRect, mq.devicePixelRatio);

    return Scaffold(
      backgroundColor: const Color(0xFF07060B),
      body: Stack(
        children: [
          Positioned.fill(
            child: _MovingBackground(animation: _motion),
          ),

          // The blur baseline is clipped to the bar, exactly as
          // GlassyBottomNav does today, so the comparison is against what the
          // package actually ships rather than a full-screen blur.
          if (_mode == ProbeMode.blur || _mode == ProbeMode.stacked)
            Positioned.fromRect(
              rect: barRect,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kBarRadius),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: _blurSigma,
                      sigmaY: _blurSigma,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),

          // The shader covers the whole screen. That is the point of the
          // experiment: it is handed the entire backdrop and masks itself with
          // the SDF, so nothing has to be captured or cropped.
          if (_mode != ProbeMode.blur && filter != null)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: filter,
                  child: const SizedBox.expand(),
                ),
              ),
            ),

          // The bar's own contents, drawn over the filtered backdrop.
          Positioned.fromRect(
            rect: barRect,
            child: _BarContents(showEdge: _mode != ProbeMode.liquidDebug),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: _Controls(
                mode: _mode,
                onMode: (mode) {
                  setState(() => _mode = mode);
                  _resetSamples();
                },
                bandWidth: _bandWidth,
                onBandWidth: (v) => setState(() => _bandWidth = v),
                amount: _amount,
                onAmount: (v) => setState(() => _amount = v),
                blurSigma: _blurSigma,
                onBlurSigma: (v) => setState(() => _blurSigma = v),
                rasterMs: _rasterMs,
                uiMs: _uiMs,
                shaderSupported: ui.ImageFilter.isShaderFilterSupported,
                programLoaded: _program != null,
                programError: _programError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content behind the glass: high-contrast bands in motion, so refraction is
/// unmistakable and the backdrop changes every frame.
class _MovingBackground extends StatelessWidget {
  const _MovingBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(
        painter: _BackgroundPainter(animation.value),
        size: Size.infinite,
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.t);

  final double t;

  static const List<Color> _colors = [
    Color(0xFFFF4D8D),
    Color(0xFF3DDC97),
    Color(0xFF2E86FF),
    Color(0xFF9B5CFF),
    Color(0xFFFFC53D),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF07060B));

    // Diagonal stripes sliding across. Straight edges make any bending of the
    // backdrop obvious at a glance.
    const stripe = 46.0;
    final shift = t * stripe * 2;
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -size.height; x < size.width + size.height; x += stripe) {
      final i = ((x / stripe).round()) % _colors.length;
      paint.color = _colors[i.abs()].withValues(alpha: 0.85);
      final path = Path()
        ..moveTo(x + shift, size.height)
        ..lineTo(x + shift + stripe * 0.5, size.height)
        ..lineTo(x + shift + stripe * 0.5 + size.height, 0)
        ..lineTo(x + shift + size.height, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();

    // A few crisp white rules, the cleanest possible refraction test.
    final rule = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    for (int i = 1; i < 9; i++) {
      final y = size.height * i / 9;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => oldDelegate.t != t;
}

/// Icons and the rim, drawn over the filtered backdrop.
class _BarContents extends StatelessWidget {
  const _BarContents({required this.showEdge});

  final bool showEdge;

  static const List<IconData> _icons = [
    Icons.home_filled,
    Icons.favorite,
    Icons.menu_book_rounded,
    Icons.queue_music_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBarRadius),
          border: showEdge
              ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final icon in _icons)
              Icon(icon, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.mode,
    required this.onMode,
    required this.bandWidth,
    required this.onBandWidth,
    required this.amount,
    required this.onAmount,
    required this.blurSigma,
    required this.onBlurSigma,
    required this.rasterMs,
    required this.uiMs,
    required this.shaderSupported,
    required this.programLoaded,
    required this.programError,
  });

  final ProbeMode mode;
  final ValueChanged<ProbeMode> onMode;
  final double bandWidth;
  final ValueChanged<double> onBandWidth;
  final double amount;
  final ValueChanged<double> onAmount;
  final double blurSigma;
  final ValueChanged<double> onBlurSigma;
  final double rasterMs;
  final double uiMs;
  final bool shaderSupported;
  final bool programLoaded;
  final Object? programError;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xEE07060B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${mode.label}   raster ${rasterMs.toStringAsFixed(2)} ms   ui ${uiMs.toStringAsFixed(2)} ms',
            style: const TextStyle(
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'shader filter: ${shaderSupported ? "supported" : "UNSUPPORTED"}'
            '   program: ${programLoaded ? "loaded" : "pending"}',
            style: TextStyle(
              color: shaderSupported ? Colors.white60 : Colors.orangeAccent,
              fontSize: 11,
            ),
          ),
          if (programError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$programError',
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              for (final m in ProbeMode.values)
                GestureDetector(
                  onTap: () => onMode(m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: m == mode ? Colors.white : Colors.white10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      m.label,
                      style: TextStyle(
                        color: m == mode ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _Slider(
            label: 'band',
            value: bandWidth,
            min: 2,
            max: 60,
            onChanged: onBandWidth,
          ),
          _Slider(
            label: 'amount',
            value: amount,
            min: 0,
            max: 80,
            onChanged: onAmount,
          ),
          _Slider(
            label: 'blur',
            value: blurSigma,
            min: 0,
            max: 40,
            onChanged: onBlurSigma,
          ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(trackHeight: 2),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
