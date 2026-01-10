import 'package:flutter_test/flutter_test.dart';
import 'package:peacekeeper/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:peacekeeper/services/debug_service.dart';
import './mock.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    DebugService.isEnabled = false;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PeacekeeperApp());

    // Verify that the app starts (finds the main title)
    expect(find.text('Peacekeeper: Couples Coach'), findsOneWidget);
  });
}