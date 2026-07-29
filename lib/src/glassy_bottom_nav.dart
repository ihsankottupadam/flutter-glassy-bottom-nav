import 'dart:ui';

import 'package:flutter/material.dart';

import 'glassy_bottom_nav_item.dart';
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
  /// Falls back to [labelStyle] when null.
  final TextStyle? selectedLabelStyle;

  /// Whether the bar is docked to the bottom edge or floats as a pill.
  final GlassyNavbarType navbarType;

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
    this.markerSize = const Size(20, 3),
    this.duration = const Duration(milliseconds: 150),
  }) : assert(items.length > 0, 'GlassyBottomNav needs at least one item.'),
       assert(
         initialIndex >= 0 && initialIndex < items.length,
         'initialIndex must point at one of the items.',
       ),
       assert(
         currentIndex == null ||
             (currentIndex >= 0 && currentIndex < items.length),
         'currentIndex must point at one of the items.',
       );

  @override
  State<GlassyBottomNav> createState() => _GlassyBottomNavState();
}

class _GlassyBottomNavState extends State<GlassyBottomNav> {
  static const Color _defaultBorderColor = Color(0x88ffffff);

  /// The selection the bar tracks itself, unused while controlled.
  late int _internalIndex = widget.initialIndex;

  /// The selected index, clamped in case the item list shrank.
  int get _currentIndex =>
      (widget.currentIndex ?? _internalIndex).clamp(0, widget.items.length - 1);

  /// The colour that tints an item's marker, and the indicator while that
  /// item is selected.
  Color _activeColorOf(GlassyBottomNavItem item) =>
      item.activeColor ?? Theme.of(context).colorScheme.secondary;

  void _onTap(int index) {
    if (_currentIndex == index) return;
    if (widget.currentIndex == null) {
      setState(() => _internalIndex = index);
    }
    widget.onChange?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.navbarType.resolveBorderRadius(
      widget.borderRadius,
    );

    return Padding(
      padding: widget.margin ?? widget.navbarType.defaultMargin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / widget.items.length;
            return Stack(
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

  TextStyle get _labelStyle => _defaultLabelStyle.merge(
    isSelected ? selectedLabelStyle ?? labelStyle : labelStyle,
  );

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
