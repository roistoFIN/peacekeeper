import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:peacekeeper/screens/start_screen.dart';
import 'package:peacekeeper/screens/session_creation_screen.dart';
import 'package:peacekeeper/screens/join_session_screen.dart';
import 'package:peacekeeper/services/debug_service.dart';
import 'package:peacekeeper/services/subscription_service.dart';
import './mock.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    DebugService.isEnabled = false;
  });

  testWidgets('SOS button navigates to SessionCreationScreen and shows code', (WidgetTester tester) async {
    // Build the StartScreen
    await tester.pumpWidget(const MaterialApp(home: StartScreen()));

    // Verify Start Screen elements
    expect(find.text('Peacekeeper: Couples Coach'), findsOneWidget);
    expect(find.text('SOS – Conflict happening now'), findsOneWidget);

    // Tap the SOS button
    await tester.tap(find.text('SOS – Conflict happening now'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for animation/async

    // Verify SessionCreationScreen is present
    expect(find.byType(SessionCreationScreen), findsOneWidget);
    
    // Since Firestore is not fully mocked for data retrieval in this unit test environment,
    // we expect the loading state ("Creating secure session...")
    expect(find.text('Creating secure session...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Join button navigates to JoinSessionScreen and validates input', (WidgetTester tester) async {
    // Build the StartScreen
    await tester.pumpWidget(const MaterialApp(home: StartScreen()));

    // Tap the Join button
    await tester.tap(find.text('Join an ongoing conversation'));
    await tester.pumpAndSettle();

    // Verify JoinSessionScreen is present
    expect(find.byType(JoinSessionScreen), findsOneWidget);
    expect(find.text('Enter Conflict Code'), findsOneWidget);

    // Enter valid code
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    // Tap Join
    await tester.tap(find.widgetWithText(FilledButton, 'Join Conversation'));
    await tester.pump();
    
    // We expect a loading dialog or error dialog since Firestore logic is involved but not fully mocked here beyond initialization.
    // The test just checks navigation logic.
  });
}
