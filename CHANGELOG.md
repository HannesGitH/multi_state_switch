## 1.1.0

* 2 states now look exactly like a Material 3 `Switch`:
  * outline around the track in the "off" position (new `inactiveTrackOutlineColor`), fading out towards the first position
  * default `stepWidth` 24 → 20, so a 2-state track is 52px wide like `Switch`
  * the widget takes up 4px extra on each side and 48px height (60×48 for 2 states), the same touch target as `Switch`

## 1.0.0

* initial release
* `MultiStateSwitch`: a switch-looking control with any number of fixed positions
* built on a discrete `Slider`: dragging, snapping, tap-to-jump, keyboard and semantics included
* track colour and thumb size animate between "off" and "on"
* customisable track / thumb colours, step width and animation duration
