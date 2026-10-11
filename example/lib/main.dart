import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:multi_state_switch/multi_state_switch.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  // light / system / dark, itself picked with a MultiStateSwitch.
  int _themeMode = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiStateSwitch demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      themeMode: const [ThemeMode.light, ThemeMode.system, ThemeMode.dark]
          [_themeMode],
      home: DemoPage(
        themeMode: _themeMode,
        onThemeModeChanged: (v) => setState(() => _themeMode = v),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final int themeMode;
  final ValueChanged<int> onThemeModeChanged;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  bool _wifi = true;
  int _vibration = 1;
  int _intensity = 2;
  int _custom = 2;

  static const _vibrationLabels = ['off', 'short', 'long'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MultiStateSwitch')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('Wi-Fi'),
            subtitle: const Text('2 states, like a regular Switch'),
            trailing: MultiStateSwitch(
              states: 2,
              value: _wifi ? 1 : 0,
              onChanged: (v) => _set(() => _wifi = v == 1),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vibration),
            title: const Text('Vibration'),
            subtitle: Text(_vibrationLabels[_vibration]),
            trailing: MultiStateSwitch(
              states: 3,
              value: _vibration,
              semanticFormatterCallback: (s) => _vibrationLabels[s],
              onChanged: (v) => _set(() => _vibration = v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Intensity'),
            subtitle: Text('level $_intensity of 4'),
            trailing: MultiStateSwitch(
              states: 5,
              value: _intensity,
              onChanged: (v) => _set(() => _intensity = v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(const ['light', 'system', 'dark'][widget.themeMode]),
            trailing: MultiStateSwitch(
              states: 3,
              value: widget.themeMode,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                widget.onThemeModeChanged(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Custom colours'),
            trailing: MultiStateSwitch(
              states: 3,
              value: _custom,
              activeTrackColor: Colors.teal,
              inactiveTrackColor: Colors.teal.shade50,
              onChanged: (v) => _set(() => _custom = v),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.block),
            title: Text('Disabled'),
            trailing: MultiStateSwitch(states: 3, value: 1, onChanged: null),
          ),
        ],
      ),
    );
  }

  void _set(VoidCallback change) {
    HapticFeedback.selectionClick();
    setState(change);
  }
}
