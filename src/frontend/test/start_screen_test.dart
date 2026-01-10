import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peacekeeper/screens/start_screen.dart';
import 'package:peacekeeper/services/subscription_service.dart';
import 'package:peacekeeper/services/debug_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import './mock.dart'; // We'll create this mock helper

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    DebugService.isEnabled = false; // Silence logs during test
  });

  testWidgets('StartScreen shows SOS and Join buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: StartScreen()));

    // Verify main title
    expect(find.text('Peacekeeper: Couples Coach'), findsOneWidget);

    // Verify buttons exist
    expect(find.textContaining('SOS'), findsOneWidget);
    expect(find.textContaining('Join an ongoing conversation'), findsOneWidget);
    expect(find.textContaining('Guide me to express'), findsOneWidget);
  });
}
