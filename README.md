# multi_state_switch

A Material 3 switch with any number of states: off / on, off / middle / on, or as many steps as you like.

![MultiStateSwitch demo](https://raw.githubusercontent.com/HannesGitH/multi_state_switch/main/assets/demo.gif)

## Features

- Looks like a Material 3 `Switch`, but with 2, 3, 5, … fixed positions
- Built on a discrete `Slider`: dragging, snapping, tap-to-jump, keyboard input and screen reader support come for free
- Track colour and thumb size animate from "off" to "on" as the position goes up
- Picks up your `ColorScheme`, or takes custom track and thumb colours
- No `CustomPainter` widget, just a small slider track shape

## Getting started

```sh
flutter pub add multi_state_switch
```

or add it to your `pubspec.yaml` manually:

```yaml
dependencies:
  multi_state_switch: ^1.0.0
```

## Usage

```dart
import 'package:multi_state_switch/multi_state_switch.dart';
```

```dart
int mode = 0; // 0 = off, 1 = middle, 2 = on

MultiStateSwitch(
  states: 3,
  value: mode,
  onChanged: (v) => setState(() => mode = v),
)
```

`value` goes from `0` ("off") to `states - 1` ("on"). Pass `onChanged: null` to disable the switch.

### Options

| parameter | default | |
|---|---|---|
| `states` | required | number of positions, at least 2 |
| `value` | required | selected position, `0 … states - 1` |
| `onChanged` | required | called with the new position; `null` disables the switch |
| `inactiveTrackColor` | `colorScheme.surfaceContainerHighest` | track colour when off |
| `activeTrackColor` | `colorScheme.primary` | track colour when on; positions in between blend |
| `inactiveThumbColor` | `colorScheme.outline` | thumb colour when off |
| `activeThumbColor` | `colorScheme.onPrimary` | thumb colour in every other position |
| `stepWidth` | `24` | distance between two positions; the switch is `32 + (states - 1) * stepWidth` wide |
| `animationDuration` | `150ms` | how fast colour and thumb size follow a change |
| `semanticFormatterCallback` | position number | what screen readers announce for a position |
| `focusNode`, `autofocus` | | as on `Slider` |

### Haptics

The switch stays silent so you can choose; add a tick in `onChanged`:

```dart
onChanged: (v) {
  HapticFeedback.selectionClick();
  setState(() => mode = v);
},
```

## Example

See [`example/`](example/lib/main.dart) for a demo app with 2, 3 and 5 state switches, a light / system / dark theme picker built from one, custom colours and a disabled switch.

## Additional information

The demo GIF is rendered by `flutter test tool/record_demo_gif.dart`.

Contributions (PRs) are welcome.
