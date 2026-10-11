import 'package:flutter_test/flutter_test.dart';
import 'package:multi_state_switch/multi_state_switch.dart';
import 'package:multi_state_switch_example/main.dart';

void main() {
  testWidgets('demo renders and the theme switch works', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.byType(MultiStateSwitch), findsNWidgets(6));

    final themeSwitch = find.byType(MultiStateSwitch).at(3);
    await tester.tapAt(tester.getRect(themeSwitch).centerRight - const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(find.text('dark'), findsOneWidget);
  });
}
