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
    this.inactiveTrackOutlineColor,
    this.stepWidth = 20,
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

  /// Outline around the track in the "off" position, like a Material 3
  /// [Switch] has. It fades out on the way to the first position.
  ///
  /// Defaults to [ColorScheme.outline].
  final Color? inactiveTrackOutlineColor;

  /// Distance between two neighbouring positions.
  ///
  /// The track is `32 + (states - 1) * stepWidth` wide, so the default makes
  /// a 2-state switch the same 52px as a Material 3 [Switch]. The widget adds
  /// 4px on each side and is 48px tall, for the same touch target.
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
  static const double _outlineWidth = 2;
  // Extra space around the track that still reacts to touch, matching the
  // 60x48 a Material 3 [Switch] takes up for its 52x32 track.
  static const double _touchPadding = 4;
  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final offTrack = inactiveTrackColor ?? cs.surfaceContainerHighest;
    final onTrack = activeTrackColor ?? cs.primary;
    final offThumb = inactiveThumbColor ?? cs.outline;
    final onThumb = activeThumbColor ?? cs.onPrimary;
    final offOutline = inactiveTrackOutlineColor ?? cs.outline;
    final enabled = onChanged != null;

    return SizedBox(
      width: 2 * (_inset + _touchPadding) + (states - 1) * stepWidth,
      height: _height,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value / (states - 1)),
          duration: animationDuration,
          curve: Curves.easeOut,
          builder: (context, t, child) {
            final track = Color.lerp(offTrack, onTrack, t)!;
            final radius = lerpDouble(_minThumbRadius, _maxThumbRadius, t)!;
            // The thumb and outline only blend between "off" and the first
            // position and stay put beyond that, see [activeThumbColor].
            final firstStep = (t * (states - 1)).clamp(0.0, 1.0);
            final thumb = Color.lerp(offThumb, onThumb, firstStep)!;
            final outline = Color.lerp(offOutline, track, firstStep)!;
            return SliderTheme(
              data: SliderThemeData(
                trackHeight: _trackHeight,
                trackShape: _PillTrackShape(
                  inset: _inset,
                  outlineColor: outline,
                  outlineWidth: _outlineWidth,
                ),
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
                // space, minus the touch padding.
                overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: _inset + _touchPadding),
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
  const _PillTrackShape({
    required this.inset,
    required this.outlineColor,
    required this.outlineWidth,
  });

  final double inset;
  final Color outlineColor;
  final double outlineWidth;

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
    final rrect =
        RRect.fromRectAndRadius(pill, Radius.circular(pill.height / 2));
    final track = sliderTheme.activeTrackColor!;
    context.canvas.drawRRect(rrect, Paint()..color = track);
    // Once the outline has faded into the track, drawing it would only
    // soften the pill's anti-aliased edge.
    if (outlineColor == track) return;
    // Stroke inside the pill so the outline doesn't grow the switch.
    context.canvas.drawRRect(
      rrect.deflate(outlineWidth / 2),
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth,
    );
  }
}
