// Renders the README demo animation to assets/demo.gif.
//
//   flutter test tool/record_demo_gif.dart
//
// It lives outside test/ so a plain `flutter test` doesn't run it. The scene
// is driven with real gestures on the light panel; the dark panel shares the
// same state and follows along.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:multi_state_switch/multi_state_switch.dart';

const _frame = Duration(milliseconds: 40); // 25 fps
const _pixelRatio = 2.0;
const _sceneSize = Size(480, 172);
const _rows = [2, 3, 5];

void main() {
  testWidgets('record demo gif', (tester) async {
    await _loadRoboto();
    tester.view
      ..physicalSize = _sceneSize * _pixelRatio
      ..devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    final values = ValueNotifier<List<int>>([0, 0, 0]);
    final boundary = GlobalKey();
    await tester.pumpWidget(_Scene(values: values, boundaryKey: boundary));

    final frames = _FrameRecorder(tester, boundary);
    Future<void> hold(Duration d) async {
      for (var t = Duration.zero; t < d; t += _frame) {
        await tester.pump(_frame);
        await frames.capture();
      }
    }

    Rect switchRect(int row) =>
        tester.getRect(find.byKey(ValueKey('light-$row')));
    Offset position(int row, int state) {
      final r = switchRect(row);
      final inner = r.deflate(16);
      return Offset(
          inner.left + inner.width * state / (_rows[row] - 1), r.center.dy);
    }

    Future<void> tap(int row, int state) async {
      await tester.tapAt(position(row, state));
      await hold(const Duration(milliseconds: 700));
    }

    Future<void> drag(int row, int from, int to) async {
      final gesture = await tester.startGesture(position(row, from));
      const steps = 30;
      for (var i = 1; i <= steps; i++) {
        final p = Offset.lerp(position(row, from), position(row, to), i / steps)!;
        await gesture.moveTo(p);
        await hold(_frame);
      }
      await gesture.up();
      await hold(const Duration(milliseconds: 700));
    }

    await hold(const Duration(milliseconds: 800));
    await tap(0, 1);
    await tap(1, 1);
    await tap(1, 2);
    await drag(2, 0, 4);
    await drag(2, 4, 1);
    await tap(2, 0);
    await tap(1, 0);
    await tap(0, 0);
    await hold(const Duration(milliseconds: 300));

    final gif = await tester.runAsync(frames.encode);
    File('assets/demo.gif').writeAsBytesSync(gif!);
  });
}

class _Scene extends StatelessWidget {
  const _Scene({required this.values, required this.boundaryKey});

  final ValueNotifier<List<int>> values;
  final GlobalKey boundaryKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: RepaintBoundary(
        key: boundaryKey,
        child: Row(children: [
          for (final b in Brightness.values.reversed)
            Expanded(
              child: Theme(
                data: ThemeData(
                  colorSchemeSeed: Colors.deepPurple,
                  brightness: b,
                  fontFamily: 'Roboto',
                ),
                child: Builder(builder: (context) => _panel(context, b)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _panel(BuildContext context, Brightness b) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: ValueListenableBuilder(
        valueListenable: values,
        builder: (context, v, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var row = 0; row < _rows.length; row++)
              SizedBox(
                height: 48,
                child: Row(children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text('${_rows[row]} states',
                        style: TextStyle(fontSize: 15, color: cs.onSurface)),
                  ),
                  MultiStateSwitch(
                    key: ValueKey('${b.name}-$row'),
                    states: _rows[row],
                    value: v[row],
                    onChanged: (n) => values.value = [...v]..[row] = n,
                  ),
                  const SizedBox(width: 16),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _FrameRecorder {
  _FrameRecorder(this.tester, this.boundaryKey);

  final WidgetTester tester;
  final GlobalKey boundaryKey;
  final _frames = <(Uint8List, int, int)>[];
  final _durations = <int>[];

  Future<void> capture() async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final result = (data!.buffer.asUint8List(), image.width, image.height);
      image.dispose();
      return result;
    });
    // Identical consecutive frames are merged into one longer frame.
    if (_frames.isNotEmpty && _sameBytes(_frames.last.$1, bytes!.$1)) {
      _durations[_durations.length - 1] += _frame.inMilliseconds ~/ 10;
      return;
    }
    _frames.add(bytes!);
    _durations.add(_frame.inMilliseconds ~/ 10);
  }

  Future<Uint8List> encode() async {
    final encoder = img.GifEncoder(
      quantizerType: img.QuantizerType.octree,
      dither: img.DitherKernel.none,
    );
    for (var i = 0; i < _frames.length; i++) {
      final (bytes, w, h) = _frames[i];
      encoder.addFrame(
        img.Image.fromBytes(
            width: w, height: h, bytes: bytes.buffer, numChannels: 4),
        duration: _durations[i],
      );
    }
    return encoder.finish()!;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Widget tests render text with a box font; load the real Roboto that ships
/// with the Flutter SDK so the labels are readable.
Future<void> _loadRoboto() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final font = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  final loader = FontLoader('Roboto')
    ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
  await loader.load();
}
