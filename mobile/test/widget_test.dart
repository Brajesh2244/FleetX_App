// Smoke test: the app boots, shows the splash screen, then lands on login.
//
// The prototype's real verification is the demo flow in flow_test.dart; this
// exists so `flutter test` covers the widget tree too.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fleetx_mobile/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('FleetX boots to the splash screen, then the login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FleetXApp());
    expect(find.text('FleetX'), findsOneWidget);

    // Let the 1.1s splash delay elapse, otherwise its timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
