import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'glass_style.dart';
import 'glassy_bottom_nav_item.dart';
import 'liquid_glass_shader.dart';
import 'glassy_navbar_type.dart';

/// A frosted-glass bottom navigation bar.
///
/// The bar blurs whatever is painted behind it, so it is meant to sit over the
/// body of a [Scaffold] with `extendBody: true`:
///
/// ```dart
/// Scaffold(
///   extendBody: true,
///   body: const MyPage(),
///   bottomNavigationBar: GlassyBottomNav(
///     items: [
///       GlassyBottomNavItem(icon: Icon(Icons.home), label: 'Home'),
///       GlassyBottomNavItem(icon: Icon(Icons.person), label: 'Profile'),
///     ],
///     onChange: (index) => setState(() => _index = index),
///   ),
/// )
/// ```
class GlassyBottomNav extends StatefulWidget {
  /// The destinations shown in the bar, laid out with equal widths.
  ///
  /// Must not be empty.
  final List<GlassyBottomNavItem> items;

  /// The index selected when the bar is first built.
  ///
  /// Ignored when [currentIndex] is given.
  final int initialIndex;

  /// The selected index, when the selection is driven from outside.
  ///
  /// Leave this null to let the bar track the selection itself. Setting it
  /// puts the bar in controlled mode: taps only report through [onChange] and
  /// the selection moves when a new [currentIndex] is passed in, which is what
  /// you want when a [PageController] or a router owns the current page.
  final int? currentIndex;

  /// Called with the new index whenever a different item is tapped.
  ///
  /// Tapping the already selected item does nothing.
  final ValueChanged<int>? onChange;

  /// Whether the selected item is highlighted with a tinted panel behind it.
  final bool showBackgroundIndicator;

  /// The space around the bar.
  ///
  /// Defaults to [GlassyNavbarType.defaultMargin] for the current
  /// [navbarType].
  final EdgeInsets? margin;

  /// The space between the bar's edges and its items.
  final EdgeInsets? padding;

  /// The blur sigma applied to whatever is painted behind the bar.
  final double backgroundBlur;

  /// Tints the glass.
  ///
  /// Applied at 10% opacity so the blurred backdrop stays visible.
  final Color? backgroundColor;

  /// The corner radius.
  ///
  /// Defaults to 25 for [GlassyNavbarType.bottom] and 50 for
  /// [GlassyNavbarType.centered].
  final double? borderRadius;

  /// The width of the border drawn around the bar.
  ///
  /// No border is drawn when null.
  final double? borderThickness;

  /// The colour of the border.
  ///
  /// Ignored unless [borderThickness] is set. Defaults to a translucent white.
  final Color? borderColor;

  /// Whether unselected items show their label.
  final bool showUnselectedLabel;

  /// Whether the selected item shows its label.
  final bool showSelectedLabel;

  /// The style of the labels.
  ///
  /// Merged over the default, which is white 12px text that fades when it
  /// overflows.
  final TextStyle? labelStyle;

  /// The style of the selected item's label.
  ///
  /// Merged over [labelStyle], so it only needs to carry what differs while
  /// the item is selected.
  final TextStyle? selectedLabelStyle;

  /// Whether the bar is docked to the bottom edge or floats as a pill.
  final GlassyNavbarType navbarType;

  /// How the bar treats what is painted behind it.
  ///
  /// Defaults to [GlassStyle.frosted], the blur the bar has always drawn.
  /// [GlassStyle.liquid] keeps that blur and bends the backdrop along the
  /// bar's edge; where its shader cannot run it falls back to
  /// [GlassStyle.frosted], so it is safe to ask for unconditionally.
  final GlassStyle glassStyle;

  /// The size of the marker drawn above the selected item's icon.
  ///
  /// The marker animates from zero width to [Size.width] on selection.
  final Size markerSize;

  /// How long the indicator and the marker take to animate between items.
  final Duration duration;

  /// Creates a frosted-glass bottom navigation bar.
  const GlassyBottomNav({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.currentIndex,
    this.onChange,
    this.borderRadius,
    this.margin,
    this.padding,
    this.backgroundBlur = 10,
    this.backgroundColor,
    this.borderThickness,
    this.borderColor,
    this.showBackgroundIndicator = true,
    this.showUnselectedLabel = true,
    this.showSelectedLabel = true,
    this.labelStyle,
    this.selectedLabelStyle,
    this.navbarType = GlassyNavbarType.centered,
    this.glassStyle = GlassStyle.frosted,
    this.markerSize = const Size(20, 3),
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<GlassyBottomNav> createState() => _GlassyBottomNavState();
}

class _GlassyBottomNavState extends State<GlassyBottomNav> {
  static const Color _defaultBorderColor = Color(0x88ffffff);

  /// How far in from the edge [GlassStyle.liquid] bends the backdrop, and
  /// how far the bent pixels travel, both in logical pixels.
  ///
  /// Not yet exposed: Phase 4 of plans/plan-liquid-glass.md tunes these
  /// against the example and decides which of them a caller ever needs.
  static const double _bandWidth = 14;
  static const double _refractionAmount = 12;

  /// The glass panel, so its rect can be read back after layout.
  final GlobalKey _panelKey = GlobalKey();

  /// The panel's rect in global logical pixels, or null before the first
  /// frame has been laid out.
  ///
  /// Measured rather than recomputed from [GlassyBottomNav.margin] and the
  /// navbar type: a caller may pass any margin, and the [Scaffold] adds
  /// insets of its own, so the only rect certain to be the one on screen is
  /// the one the render object reports.
  Rect? _panelRect;

  /// The selection the bar tracks itself, unused while controlled.
  late int _internalIndex = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    assert(
      widget.initialIndex >= 0 && widget.initialIndex < widget.items.length,
      'initialIndex must point at one of the items.',
    );
  }

  /// The selected index, clamped in case the item list shrank.
  int get _currentIndex =>
      (widget.currentIndex ?? _internalIndex).clamp(0, widget.items.length - 1);

  /// The style actually drawn, which is [GlassStyle.frosted] whenever the
  /// backend cannot run [GlassStyle.liquid]'s shader.
  ///
  /// Everything that draws differently per style reads this rather than
  /// `widget.glassStyle`, so the fallback is decided in one place.
  GlassStyle get _resolvedStyle => widget.glassStyle.resolved;

  /// Reads the panel's rect back after a frame, and rebuilds if it moved.
  ///
  /// The refraction is a frame behind the geometry, which shows only while
  /// the bar is changing size — a rotation, a window drag. The alternative
  /// is a custom render object built to hand its own paint-time position to
  /// a filter, which is a great deal of machinery for one frame during a
  /// resize.
  void _measurePanel() {
    final RenderObject? object = _panelKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) return;
    final Rect rect = object.localToGlobal(Offset.zero) & object.size;
    if (rect == _panelRect) return;
    setState(() => _panelRect = rect);
  }

  /// Makes sure the shader is compiling, and rebuilds when it arrives.
  void _ensureShader() {
    if (LiquidGlassShader.program != null || LiquidGlassShader.failed) return;
    LiquidGlassShader.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// The refraction filter, or null whenever the bar should not draw one —
  /// the style resolved to frosted, the shader has not compiled yet, or the
  /// panel has not been measured. Each of those draws the frosted bar for
  /// this frame rather than holding it up.
  ImageFilter? _refraction(BorderRadius borderRadius) {
    if (_resolvedStyle != GlassStyle.liquid) return null;

    final FragmentProgram? program = LiquidGlassShader.program;
    final Rect? rect = _panelRect;
    if (program == null || rect == null) return null;

    // Everything the shader is told is in device pixels, because
    // FlutterFragCoord() is.
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final FragmentShader shader = program.fragmentShader();
    shader
      // Floats 0 and 1 are uTextureSize, which the engine overwrites with
      // the size of the texture it binds.
      ..setFloat(0, 0)
      ..setFloat(1, 0)
      ..setFloat(2, rect.left * dpr)
      ..setFloat(3, rect.top * dpr)
      ..setFloat(4, rect.right * dpr)
      ..setFloat(5, rect.bottom * dpr)
      ..setFloat(6, borderRadius.topLeft.x * dpr)
      ..setFloat(7, borderRadius.topRight.x * dpr)
      ..setFloat(8, borderRadius.bottomRight.x * dpr)
      ..setFloat(9, borderRadius.bottomLeft.x * dpr)
      ..setFloat(10, _bandWidth * dpr)
      ..setFloat(11, _refractionAmount * dpr);
    return ImageFilter.shader(shader);
  }

  /// The colour that tints an item's marker, and the indicator while that
  /// item is selected.
  Color _activeColorOf(GlassyBottomNavItem item) =>
      item.activeColor ?? Theme.of(context).colorScheme.secondary;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<GlassStyle>('glassStyle', widget.glassStyle));
    // Worth reporting separately only when the two differ, which is the
    // case the inspector cannot otherwise show: a bar asked for
    // GlassStyle.liquid on a backend that cannot draw it looks like a bar
    // that was asked for GlassStyle.frosted.
    properties.add(
      EnumProperty<GlassStyle>(
        'resolvedStyle',
        _resolvedStyle,
        defaultValue: widget.glassStyle,
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    if (widget.currentIndex == null) {
      setState(() => _internalIndex = index);
    }
    widget.onChange?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    // Checked here rather than in the constructor: a const constructor cannot
    // evaluate items.length, which would rule out const GlassyBottomNav(...).
    assert(widget.items.isNotEmpty, 'GlassyBottomNav needs at least one item.');
    assert(
      widget.currentIndex == null ||
          (widget.currentIndex! >= 0 &&
              widget.currentIndex! < widget.items.length),
      'currentIndex must point at one of the items.',
    );

    final borderRadius = widget.navbarType.resolveBorderRadius(
      widget.borderRadius,
    );

    // Both are no-ops while the bar is frosted, which is what keeps a
    // frosted bar from touching the shader asset or scheduling callbacks.
    if (_resolvedStyle == GlassStyle.liquid) {
      _ensureShader();
      WidgetsBinding.instance.addPostFrameCallback((_) => _measurePanel());
    }

    final ImageFilter? refraction = _refraction(borderRadius);

    return Padding(
      padding: widget.margin ?? widget.navbarType.defaultMargin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / widget.items.length;
            return Stack(
              key: _panelKey,
              children: [
                if (widget.showBackgroundIndicator)
                  AnimatedPositioned(
                    left: itemWidth * _currentIndex,
                    width: itemWidth,
                    top: 0,
                    bottom: 0,
                    duration: widget.duration,
                    child: AnimatedContainer(
                      duration: widget.duration,
                      color: _activeColorOf(
                        widget.items[_currentIndex],
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.backgroundBlur,
                    sigmaY: widget.backgroundBlur,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor?.withValues(alpha: 0.1),
                      borderRadius: borderRadius,
                      border: widget.borderThickness == null
                          ? null
                          : Border.all(
                              width: widget.borderThickness!,
                              color: widget.borderColor ?? _defaultBorderColor,
                            ),
                    ),
                    padding: widget.padding ?? EdgeInsets.zero,
                    child: Row(
                      children: [
                        for (final (index, item) in widget.items.indexed)
                          Expanded(
                            child: Tooltip(
                              message: item.label,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _onTap(index),
                                child: _GlassyBottomNavItemView(
                                  item: item,
                                  isSelected: index == _currentIndex,
                                  activeColor: _activeColorOf(item),
                                  showSelectedLabel: widget.showSelectedLabel,
                                  showUnselectedLabel:
                                      widget.showUnselectedLabel,
                                  labelStyle: widget.labelStyle,
                                  selectedLabelStyle: widget.selectedLabelStyle,
                                  markerSize: widget.markerSize,
                                  animationDuration: widget.duration,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // The rim refraction, above the blur so that what it
                // bends is already blurred, and positioned so it does not
                // take part in the Stack's sizing. It covers the panel
                // rather than the screen, because a bar handed to
                // Scaffold.bottomNavigationBar has no way to paint outside
                // its own box -- and it does not need to, since the bend
                // samples inwards from the edge.
                if (refraction != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: BackdropFilter(
                        filter: refraction,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The icon, marker and label of a single destination.
class _GlassyBottomNavItemView extends StatelessWidget {
  const _GlassyBottomNavItemView({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.showUnselectedLabel,
    required this.showSelectedLabel,
    required this.labelStyle,
    required this.selectedLabelStyle,
    required this.markerSize,
    required this.animationDuration,
  });

  static const TextStyle _defaultLabelStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    overflow: TextOverflow.fade,
  );

  final GlassyBottomNavItem item;
  final bool isSelected;
  final Color activeColor;
  final bool showUnselectedLabel;
  final bool showSelectedLabel;
  final TextStyle? labelStyle;
  final TextStyle? selectedLabelStyle;
  final Size markerSize;
  final Duration animationDuration;

  Widget get _icon => isSelected ? item.activeIcon ?? item.icon : item.icon;

  bool get _showLabel => isSelected ? showSelectedLabel : showUnselectedLabel;

  TextStyle get _labelStyle {
    final style = _defaultLabelStyle.merge(labelStyle);
    return isSelected ? style.merge(selectedLabelStyle) : style;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: animationDuration,
          width: isSelected ? markerSize.width : 0,
          height: markerSize.height,
          color: activeColor,
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: isSelected ? 1 : 0.4,
          child: Column(
            children: [
              _icon,
              const SizedBox(height: 5),
              if (_showLabel) Text(item.label, maxLines: 1, style: _labelStyle),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
