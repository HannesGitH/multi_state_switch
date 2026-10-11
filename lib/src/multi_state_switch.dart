import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// A switch-looking control with [states] fixed positions.
///
/// Two states behave like a regular on/off [Switch], three give
/// off / middle / on, and so on.
///
/// It is built on a discrete [Slider], so dragging, snapping, tap-to-jump,
/// keyboard input and semantics come for free. The track colour and thumb
/// size move from "off" to "on" in proportion to the selected position.
class MultiStateSwitch extends StatelessWidget {
  /// Creates a switch with [states] positions, currently at [value].
  const MultiStateSwitch({
    super.key,
    required this.states,
    required this.value,
    required this.onChanged,
    this.inactiveTrackColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.activeThumbColor,
    this.stepWidth = 24,
    this.animationDuration = const Duration(milliseconds: 150),
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
  })  : assert(states >= 2, 'a switch needs at least two states'),
        assert(value >= 0 && value < states, 'value must be in [0, states)');

  /// Number of positions the thumb can snap to. At least 2.
  final int states;

  /// Selected position, from 0 (off) to [states] - 1 (on).
  final int value;

  /// Called with the new position when the user picks one.
  ///
  /// The switch is disabled when this is null.
  final ValueChanged<int>? onChanged;

  /// Track colour in the "off" position.
  ///
  /// Defaults to [ColorScheme.surfaceContainerHighest].
  final Color? inactiveTrackColor;

  /// Track colour in the "on" position. Positions in between blend from
  /// [inactiveTrackColor] to this.
  ///
  /// Defaults to [ColorScheme.primary].
  final Color? activeTrackColor;

  /// Thumb colour in the "off" position.
  ///
  /// Defaults to [ColorScheme.outline].
  final Color? inactiveThumbColor;

  /// Thumb colour in every position other than "off".
  ///
  /// Intermediate positions use this too instead of a blend, as a blended
  /// thumb turns a muddy grey that disappears against the track.
  ///
  /// Defaults to [ColorScheme.onPrimary].
  final Color? activeThumbColor;

  /// Distance between two neighbouring positions. The switch is
  /// `32 + (states - 1) * stepWidth` wide.
  final double stepWidth;

  /// How long the track colour and thumb size take to follow a change.
  final Duration animationDuration;

  /// Describes a position for screen readers. Defaults to the position
  /// number.
  final String Function(int state)? semanticFormatterCallback;

  /// See [Slider.focusNode].
  final FocusNode? focusNode;

  /// See [Slider.autofocus].
  final bool autofocus;

  static const double _trackHeight = 32;
  static const double _minThumbRadius = 8;
  static const double _maxThumbRadius = 12;
  // Space between the track's rounded end and the thumb's centre at the
  // outermost positions: the biggest thumb radius plus a 4px gap.
  static const double _inset = _maxThumbRadius + 4;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final offTrack = inactiveTrackColor ?? cs.surfaceContainerHighest;
    final onTrack = activeTrackColor ?? cs.primary;
    final offThumb = inactiveThumbColor ?? cs.outline;
    final onThumb = activeThumbColor ?? cs.onPrimary;
    final enabled = onChanged != null;

    return SizedBox(
      width: 2 * _inset + (states - 1) * stepWidth,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value / (states - 1)),
          duration: animationDuration,
          curve: Curves.easeOut,
          builder: (context, t, child) {
            final track = Color.lerp(offTrack, onTrack, t)!;
            final radius = lerpDouble(_minThumbRadius, _maxThumbRadius, t)!;
            // The thumb only blends between "off" and the first position and
            // keeps the "on" colour beyond that, see [activeThumbColor].
            final thumb = Color.lerp(
                offThumb, onThumb, (t * (states - 1)).clamp(0.0, 1.0))!;
            return SliderTheme(
              data: SliderThemeData(
                trackHeight: _trackHeight,
                trackShape: const _PillTrackShape(_inset),
                activeTrackColor: track,
                inactiveTrackColor: track,
                disabledActiveTrackColor: track,
                disabledInactiveTrackColor: track,
                thumbColor: thumb,
                disabledThumbColor: thumb,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: radius,
                  disabledThumbRadius: radius,
                  elevation: 0,
                  pressedElevation: 0,
                ),
                // The overlay radius sets how far the track is inset from the
                // widget edges; _PillTrackShape paints back out into that
                // space.
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: _inset),
                overlayColor: Colors.transparent,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: child!,
            );
          },
          child: Slider(
            value: value.toDouble(),
            max: (states - 1).toDouble(),
            divisions: states - 1,
            focusNode: focusNode,
            autofocus: autofocus,
            semanticFormatterCallback: (v) =>
                semanticFormatterCallback?.call(v.round()) ?? '${v.round()}',
            onChanged: onChanged == null
                ? null
                : (v) {
                    final next = v.round();
                    if (next != value) onChanged!(next);
                  },
          ),
        ),
      ),
    );
  }
}

/// Paints a single pill that extends [inset] past both ends of the slider's
/// track rect, so the thumb sits inside the pill at the outermost positions
/// instead of overhanging it.
class _PillTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _PillTrackShape(this.inset);

  final double inset;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final pill = Rect.fromLTRB(
        rect.left - inset, rect.top, rect.right + inset, rect.bottom);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(pill, Radius.circular(pill.height / 2)),
      Paint()..color = sliderTheme.activeTrackColor!,
    );
  }
}
