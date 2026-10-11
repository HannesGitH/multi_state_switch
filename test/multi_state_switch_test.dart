import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:multi_state_switch/multi_state_switch.dart';

Widget _host({required int states, required ValueChanged<int> onChanged}) {
  var value = 0;
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: StatefulBuilder(
          builder: (context, setState) => MultiStateSwitch(
            states: states,
            value: value,
            onChanged: (v) {
              onChanged(v);
              setState(() => value = v);
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tap and drag snap to the nearest state', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_host(states: 3, onChanged: changes.add));
    final box = tester.getRect(find.byType(MultiStateSwitch));

    await tester.tapAt(box.centerRight - const Offset(4, 0));
    await tester.pumpAndSettle();
    await tester.tapAt(box.center);
    await tester.pumpAndSettle();
    await tester.dragFrom(box.center, const Offset(-60, 0));
    await tester.pumpAndSettle();

    expect(changes, [2, 1, 0]);
  });

  testWidgets('size grows with the number of states', (tester) async {
    await tester.pumpWidget(_host(states: 2, onChanged: (_) {}));
    final two = tester.getSize(find.byType(MultiStateSwitch));
    await tester.pumpWidget(_host(states: 5, onChanged: (_) {}));
    final five = tester.getSize(find.byType(MultiStateSwitch));
    // Same footprint as a Material 3 Switch.
    expect(two, const Size(60, 48));
    expect(five, const Size(120, 48));
  });

  testWidgets('disabled switch ignores taps', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: MultiStateSwitch(states: 3, value: 0, onChanged: null),
        ),
      ),
    ));
    await tester.tap(find.byType(MultiStateSwitch));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  testWidgets('semantics use the formatter', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: MultiStateSwitch(
            states: 3,
            value: 1,
            semanticFormatterCallback: (s) => ['off', 'half', 'on'][s],
            onChanged: (_) {},
          ),
        ),
      ),
    ));
    expect(find.semantics.byValue('half'), findsOne);
    final node = find.semantics.byValue('half').evaluate().single;
    expect(node.getSemanticsData().increasedValue, 'on');
    expect(node.getSemanticsData().decreasedValue, 'off');
    handle.dispose();
  });
}
