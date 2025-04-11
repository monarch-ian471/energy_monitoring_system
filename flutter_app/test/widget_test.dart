import 'package:flutter_test/flutter_test.dart';
import 'package:energy_monitor_app/main.dart';

void main() {
  testWidgets('Energy Monitor App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EnergyMonitorApp());
    expect(find.text('Energy Monitor'), findsOneWidget);
  });
}